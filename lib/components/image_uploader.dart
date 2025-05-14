// lib/utils/image_uploader.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class ImageUploader {
  static final Map<String, AssetEntity> _uuidToAssetMap = {};

  /// UUID - AssetEntity 매핑 조회용 (Grid 표시용)
  static Map<String, AssetEntity> get uuidAssetMap => _uuidToAssetMap;

  /// 전체 사진을 불러와 UUID와 매핑하여 저장
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

  /// 압축 → base64 → TEXT 업로드
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

  /// 서버로부터 받은 UUID 리스트 기반 필터링된 Asset 목록 반환
  static List<AssetEntity> filterAssetsByUuidList(List<String> uuidList) {
    return uuidList.map((uuid) => _uuidToAssetMap[uuid]).whereType<AssetEntity>().toList();
  }
}
