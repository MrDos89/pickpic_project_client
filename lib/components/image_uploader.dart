import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:pickpic_project_client/page/loading_overlay.dart';

class ImageUploader {
  static final Map<String, AssetEntity> _uuidToAssetMap = {};

  static Map<String, AssetEntity> get uuidAssetMap => _uuidToAssetMap;

  static Future<void> prepareAllImages({int maxCount = 999}) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return;

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return;

    final assets = await albums.first.getAssetListPaged(page: 0, size: maxCount);
    _uuidToAssetMap.clear();

    for (final asset in assets) {
      _uuidToAssetMap[asset.id] = asset;
    }

    debugPrint('🧩 총 저장된 uuidAssetMap 키: ${_uuidToAssetMap.length}');
    for (final key in _uuidToAssetMap.keys.take(20)) {
      debugPrint(' - $key');
    }
  }

  static Future<Uint8List> _compressImageWithParams(Uint8List bytes, int minWidth, int minHeight) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: 80,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (e) {
      debugPrint("⚠️ 압축 실패, 원본 사용: $e");
      return bytes;
    }
  }

  static Future<Map<String, dynamic>?> _processAsset(MapEntry<String, AssetEntity> entry) async {
    try {
      final uuid = entry.key;
      final entity = entry.value;
      final originBytes = await entity.originBytes;
      if (originBytes == null || originBytes.isEmpty) {
        debugPrint("🚫 [$uuid] originBytes 로딩 실패 → 업로드 스킵");
        return null;
      }

      final size = await entity.size;
      final isLandscape = size.width >= size.height;
      final minWidth = isLandscape ? 256 : (256 * size.width / size.height).round();
      final minHeight = isLandscape ? (256 * size.height / size.width).round() : 256;

      final compressedBytes = await _compressImageWithParams(originBytes, minWidth, minHeight);
      final base64Image = base64Encode(compressedBytes);

      return {
        "uid": uuid,
        "image_data": base64Image,
        "ssid": "test",
      };
    } catch (e, stack) {
      debugPrint("❌ 예외 발생: $e");
      debugPrint("⛔ Stacktrace: $stack");
      return null;
    }
  }

  static Future<void> compressAndBatchUploadImages({
    required BuildContext context,
    required String uploadUrl,
    void Function(String)? onSuccess,
    void Function(String)? onError,
  }) async {
    LoadingOverlay.show(context, message: "업로드 중... 연결 확인 중입니다");
    final stopwatch = Stopwatch()..start();

    try {
      final tasks = _uuidToAssetMap.entries.map((e) => _processAsset(e));
      final results = await Future.wait(tasks);
      final imagePayloads = results.whereType<Map<String, dynamic>>().toList();

      final jsonPayload = jsonEncode({"images": imagePayloads});

      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonPayload,
      );

      stopwatch.stop();

      if (response.statusCode == 200) {
        final msg = "✅ ${imagePayloads.length}개 업로드 성공 / ⏱ ${stopwatch.elapsedMilliseconds}ms";
        debugPrint(msg);
        onSuccess?.call(msg);
      } else {
        debugPrint("❌ 업로드 실패: status=${response.statusCode}, body=${response.body}");
        onError?.call("❌ 서버 응답 오류: ${response.statusCode} (${response.body})");
      }
    } catch (e) {
      stopwatch.stop();
      onError?.call("전체 처리 중 예외 발생: $e (⏱ ${stopwatch.elapsedMilliseconds}ms)");
    } finally {
      LoadingOverlay.hide(context);
    }
  }

  static List<AssetEntity> filterAssetsByUuidList(List<String> uuidList) {
    for (final uuid in uuidList) {
      if (_uuidToAssetMap.containsKey(uuid)) {
        debugPrint('✅ 매칭됨: $uuid');
      } else {
        debugPrint('❌ 없음: $uuid');
      }
    }

    final filtered = uuidList
        .map((uuid) => _uuidToAssetMap[uuid])
        .whereType<AssetEntity>()
        .toList();

    debugPrint("🔍 서버에서 받은 UUID ${uuidList.length}개 → 최종 이미지 ${filtered.length}개");

    return filtered;
  }

  static final Map<String, List<String>> _poseToUuidListMap = {};

  static Map<String, List<String>> get poseToUuidListMap => _poseToUuidListMap;

  static const Map<String, String> _poseKorToKeyword = {
    '만세 포즈': '만세',
    '점프샷 포즈': '점프',
    '서있는 포즈': '서있음',
    '앉은 포즈': '앉음',
    '누워있는 포즈': '누워있음',
    '브이 손동작 포즈': '브이',
    '하트 손동작 포즈': '하트',
    '최고 손동작 포즈': '최고',
  };

  static Future<void> fetchAllPoseUuidListsFromServer() async {
    for (final poseKor in _poseKorToKeyword.keys) {
      final keyword = _poseKorToKeyword[poseKor];
      if (keyword == null) continue;

      try {
        final response = await http.post(
          Uri.parse("http://192.168.0.248:8080/data/txt2img"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({"ssid": "test", "keyword": keyword}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data['results'] is List) {
            final filenames = (data['results'] as List)
                .map((item) => item['filename'])
                .whereType<String>()
                .map((name) => name.replaceAll('.jpg', ''))
                .toList();
            _poseToUuidListMap[poseKor] = filenames;
          }
        } else {
          debugPrint("❌ [$poseKor] 응답 실패: ${response.statusCode} (${response.body})");
        }
      } catch (e) {
        debugPrint("❌ [$poseKor] UUID 리스트 가져오기 실패: $e");
      }
    }
  }
}
