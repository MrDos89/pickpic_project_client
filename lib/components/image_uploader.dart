// lib/utils/image_uploader.dart

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

  /// GCP Cloud Storage Signed URL 방식으로 업로드
  static Future<void> uploadToCloudStorage({
    required Future<String> Function(String uuid) getSignedUrl, // 서버에서 signed URL 발급
    void Function(String)? onSuccess,
    void Function(String)? onError,
  }) async {
    try {
      for (final entry in _uuidToAssetMap.entries) {
        final uuid = entry.key;
        final asset = entry.value;

        final originBytes = await asset.originBytes;
        if (originBytes == null) continue;

        final compressed = await FlutterImageCompress.compressWithList(
          originBytes,
          minWidth: 256,
          minHeight: 256,
          quality: 80,
          format: CompressFormat.jpeg,
        );

        final signedUrl = await getSignedUrl(uuid); // 서버에서 사전 발급

        final response = await http.put(
          Uri.parse(signedUrl),
          headers: {
            'Content-Type': 'image/jpeg',
          },
          body: compressed,
        );

        if (response.statusCode != 200) {
          onError?.call("❌ $uuid 업로드 실패 (status: ${response.statusCode})");
        }
      }

      onSuccess?.call("✅ 전체 업로드 완료");
    } catch (e) {
      onError?.call("오류 발생: $e");
    }
  }

  static List<AssetEntity> filterAssetsByUuidList(List<String> uuidList) {
    return uuidList.map((uuid) => _uuidToAssetMap[uuid]).whereType<AssetEntity>().toList();
  }
}