import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
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

  static Future<void> compressAndBatchUploadImages({
    required BuildContext context,
    required String uploadUrl,
    void Function(String)? onSuccess,
    void Function(String)? onError,
  }) async {
    LoadingOverlay.show(context, message: "업로드 중... 연결 확인 중입니다");
    final stopwatch = Stopwatch()..start();
    final ssid = "edlag12345sd3sdf!da";

    try {
      final List<Map<String, dynamic>> imagePayloads = [];
      int skipped = 0;

      for (final entry in _uuidToAssetMap.entries) {
        final uuid = entry.key;
        final entity = entry.value;

        Uint8List? originBytes;
        try {
          originBytes = await entity.originBytes;
          if (originBytes == null || originBytes.isEmpty) {
            debugPrint("🚫 [$uuid] originBytes 로딩 실패 → 업로드 스킵");
            skipped++;
            continue;
          }
        } catch (e) {
          debugPrint("🚫 [$uuid] originBytes 예외 발생: $e → 업로드 스킵");
          skipped++;
          continue;
        }

        final size = await entity.size;
        final isLandscape = size.width >= size.height;
        final minWidth = isLandscape ? 256 : (256 * size.width / size.height).round();
        final minHeight = isLandscape ? (256 * size.height / size.width).round() : 256;

        Uint8List compressedBytes;
        try {
          compressedBytes = await FlutterImageCompress.compressWithList(
            originBytes,
            minWidth: minWidth,
            minHeight: minHeight,
            quality: 80,
            format: CompressFormat.jpeg,
          ) ?? originBytes;
        } catch (e) {
          debugPrint("⚠️ [$uuid] 압축 실패, 원본 사용");
          compressedBytes = originBytes;
        }

        final base64Image = base64Encode(compressedBytes);

        imagePayloads.add({
          "uid": uuid,
          "image_data": base64Image,
          "ssid": ssid,
        });
      }

      final jsonPayload = jsonEncode({"images": imagePayloads});

      try {
        final response = await http.post(
          Uri.parse(uploadUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonPayload,
        );

        stopwatch.stop();

        if (response.statusCode == 200) {
          final msg = "✅ ${imagePayloads.length}개 업로드 성공 / $skipped개 스킵됨 ⏱ ${stopwatch.elapsedMilliseconds}ms";
          debugPrint(msg);
          onSuccess?.call(msg);
        } else {
          debugPrint("❌ 업로드 실패: status=${response.statusCode}, body=${response.body}");
          onError?.call("❌ 서버 응답 오류: ${response.statusCode} (${response.body})");
        }
      } catch (e) {
        stopwatch.stop();
        debugPrint("❌ 업로드 중 네트워크 예외 발생: $e");
        onError?.call("❌ 네트워크 오류로 업로드 실패: $e");
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
      final poseEng = _poseKorToKeyword[poseKor];
      if (poseEng == null) continue;

      try {
        final response = await http.get(Uri.parse("http://192.168.0.248:8080/pose/$poseEng"));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            _poseToUuidListMap[poseKor] = List<String>.from(data);
          }
        } else {
          debugPrint("❌ [$poseKor] 응답 실패: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("❌ [$poseKor] UUID 리스트 가져오기 실패: $e");
      }
    }
  }
}
