import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
// import 'package:wifi_info_plus/wifi_info_plus.dart';
import 'package:pickpic_project_client/page/loading_overlay.dart';

class ImageUploader {
  static final Map<String, AssetEntity> _uuidToAssetMap = {};

  static Map<String, AssetEntity> get uuidAssetMap => _uuidToAssetMap;

  static Future<void> prepareAllImages({int maxCount = 999 }) async {
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
      final uuid = const Uuid().v4();
      _uuidToAssetMap[uuid] = asset;
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

      for (final entry in List<MapEntry<String, AssetEntity>>.from(_uuidToAssetMap.entries)) {
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
    return uuidList
        .map((uuid) => _uuidToAssetMap[uuid])
        .whereType<AssetEntity>()
        .toList();
  }

  static final Map<String, List<String>> _poseToUuidListMap = {};

  static Map<String, List<String>> get poseToUuidListMap => _poseToUuidListMap;

  static const Map<String, String> _poseKorToEng = {
    '만세 포즈': 'hands_up',
    '점프샷 포즈': 'jump_shot',
    '서있는 포즈': 'standing',
    '앉은 포즈': 'sitting',
    '누워있는 포즈': 'lying',
    '브이 손동작 포즈': 'v_sign',
    '하트 손동작 포즈': 'heart_sign',
    '최고 손동작 포즈': 'thumbs_up',
  };

  static Future<void> fetchAllPoseUuidListsFromServer() async {
    for (final poseKor in _poseKorToEng.keys) {
      final poseEng = _poseKorToEng[poseKor];
      if (poseEng == null) continue;

      try {
        final response = await http.get(Uri.parse("http://192.168.0.247:8080/pose/$poseEng"));
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
