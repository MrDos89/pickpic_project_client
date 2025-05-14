// lib/utils/image_uploader.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class ImageUploader {
  static final Map<String, AssetEntity> _uuidToAssetMap = {};

  static Map<String, AssetEntity> get uuidAssetMap => _uuidToAssetMap;

  static Future<void> prepareAllImages({int maxCount = 300}) async {
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

  /// 로컬 서버로 TEXT 업로드 방식 복원
  static Future<void> compressAndUploadMappedImages({
    required String uploadUrl,
    void Function(String)? onSuccess,
    void Function(String)? onError,
  }) async {
    try {
      final Map<String, Uint8List> compressedMap = {};

      for (final entry in _uuidToAssetMap.entries) {
        final uuid = entry.key;
        final originBytes = await entry.value.originBytes;
        if (originBytes == null) continue;

        final compressed = await FlutterImageCompress.compressWithList(
          originBytes,
          minWidth: 256,
          minHeight: 256,
          quality: 80,
          format: CompressFormat.jpeg,
        );

        compressedMap[uuid] = compressed ?? originBytes;
      }

      final String payload = compressedMap.entries
          .map((e) => "${e.key}:${base64Encode(e.value)}")
          .join('\n');

      final response = await http.post(
        Uri.parse(uploadUrl),
        headers: {"Content-Type": "text/plain"},
        body: payload,
      );

      if (response.statusCode == 200) {
        onSuccess?.call("✅ 업로드 성공");
      } else {
        onError?.call("❌ 서버 오류: \${response.statusCode}");
      }
    } catch (e) {
      onError?.call("전송 오류: \$e");
    }
  }

  static List<AssetEntity> filterAssetsByUuidList(List<String> uuidList) {
    return uuidList.map((uuid) => _uuidToAssetMap[uuid]).whereType<AssetEntity>().toList();
  }
}