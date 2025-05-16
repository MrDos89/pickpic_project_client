import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
// import 'package:wifi_info_plus/wifi_info_plus.dart';

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

  // compute에서 사용할 isolate-safe 함수
  static Future<Uint8List> compressInIsolate(Map<String, dynamic> data) async {
    final List<int> inputBytes = List<int>.from(data['bytes']);
    return await FlutterImageCompress.compressWithList(
      Uint8List.fromList(inputBytes),
      minWidth: data['minWidth'],
      minHeight: data['minHeight'],
      quality: data['quality'],
      format: CompressFormat.jpeg,
    ) ?? Uint8List.fromList(inputBytes);
  }

  static Future<void> compressAndUploadMappedImagesParallel({
    required String uploadUrl,
    void Function(String)? onSuccess,
    void Function(String)? onError,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // final wifiInfo = WifiInfo();
      // final ssid = await wifiInfo.getWifiName() ?? "unknown";
      final ssid = "test";

      final tasks = <Future<void>>[];

      for (final entry in _uuidToAssetMap.entries) {
        final uuid = entry.key;
        final entity = entry.value;

        final originBytes = await entity.originBytes;
        if (originBytes == null) continue;

        final size = await entity.size;
        final isLandscape = size.width >= size.height;
        final minWidth = isLandscape ? 256 : (256 * size.width / size.height).round();
        final minHeight = isLandscape ? (256 * size.height / size.width).round() : 256;

        final task = compute(compressInIsolate, {
          'bytes': originBytes,
          'minWidth': minWidth,
          'minHeight': minHeight,
          'quality': 80,
        }).then((compressedBytes) async {
          final base64Image = base64Encode(compressedBytes);
          final payload = jsonEncode({
            "context": base64Image,
            "ssid": ssid,
          });

          final response = await http.post(
            Uri.parse('$uploadUrl/$uuid'),
            headers: {"Content-Type": "application/json"},
            body: payload,
          );

          if (response.statusCode != 200) {
            debugPrint("❌ $uuid 업로드 실패: ${response.statusCode}");
            onError?.call("❌ $uuid 업로드 실패 (body: ${response.body})");
          }
        });

        tasks.add(task);
      }

      await Future.wait(tasks);

      stopwatch.stop();
      final elapsed = stopwatch.elapsed.inMilliseconds;
      debugPrint("✅ 전체 작업 완료 (${tasks.length}개), 소요 시간: ${elapsed}ms");

      onSuccess?.call("✅ 전체 업로드 완료 (${tasks.length}개), 시간: ${elapsed}ms");
    } catch (e) {
      stopwatch.stop();
      onError?.call("전송 오류: ${e.toString()} (⏱ ${stopwatch.elapsed.inMilliseconds}ms)");
    }
  }

  static List<AssetEntity> filterAssetsByUuidList(List<String> uuidList) {
    return uuidList.map((uuid) => _uuidToAssetMap[uuid]).whereType<AssetEntity>().toList();
  }
}
