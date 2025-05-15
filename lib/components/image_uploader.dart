import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
// import 'package:wifi_info_plus/wifi_info_plus.dart'; // SSID 가져오기용

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

  static Future<void> compressAndUploadMappedImages({
    required String uploadUrl,
    void Function(String)? onSuccess,
    void Function(String)? onError,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // final wifiInfo = WifiInfo(); // SSID 가져오기
      // final ssid = await wifiInfo.getWifiName() ?? "unknown";
      final ssid = await "test";

      final List<Map<String, dynamic>> imageList = [];

      for (final entry in _uuidToAssetMap.entries.toList()) {
        final uuid = entry.key;
        final originBytes = await entry.value.originBytes;
        if (originBytes == null) continue;

        final size = await entry.value.size;
        final int width = size.width.toInt();
        final int height = size.height.toInt();

        final bool isLandscape = width >= height;
        final int targetWidth = isLandscape ? 256 : (256 * width / height).round();
        final int targetHeight = isLandscape ? (256 * height / width).round() : 256;

        final compressed = await FlutterImageCompress.compressWithList(
          originBytes,
          minWidth: targetWidth,
          minHeight: targetHeight,
          quality: 80,
          format: CompressFormat.jpeg,
        );

        final data = compressed ?? originBytes;
        final base64Image = base64Encode(data);

        imageList.add({
          "image_data": base64Image,
          "ssid": ssid,
          "index": uuid,
        });
      }

      final jsonPayload = jsonEncode({"images": imageList});

      debugPrint("전송할 JSON 배열 (앞 100자): ${jsonPayload.substring(0, 100)}");

      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonPayload,
      );

      stopwatch.stop();
      debugPrint("⏱️ 전송 소요 시간: ${stopwatch.elapsedMilliseconds}ms");

      if (response.statusCode != 200) {
        debugPrint("서버 응답 코드: ${response.statusCode}");
        debugPrint("서버 응답 본문: ${response.body}");
        onError?.call("❌ 일괄 업로드 실패 (status: ${response.statusCode}, body: ${response.body})");
      } else {
        onSuccess?.call("✅ 전체 업로드 완료");
      }
    } catch (e) {
      onError?.call("전송 오류: " + e.toString());
    }
  }

  static List<AssetEntity> filterAssetsByUuidList(List<String> uuidList) {
    return uuidList.map((uuid) => _uuidToAssetMap[uuid]).whereType<AssetEntity>().toList();
  }
}
