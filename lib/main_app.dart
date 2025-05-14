// lib/main_app.dart

import 'package:flutter/material.dart';
import 'package:pickpic_project_client/components/gallery_image_grid.dart';
import 'package:pickpic_project_client/components/image_uploader.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<String>? _serverUuidList;
  bool _isUploading = true;

  @override
  void initState() {
    super.initState();
    _prepareAndUploadImages();
  }

  Future<void> _prepareAndUploadImages() async {
    await ImageUploader.prepareAllImages();

    await ImageUploader.compressAndUploadMappedImages(
      uploadUrl: "https://your.api/upload",
      onSuccess: (msg) {
        debugPrint(msg);
        // ✅ 서버에서 UUID 리스트 받았다고 가정 (샘플)
        setState(() {
          _serverUuidList = ImageUploader.uuidAssetMap.keys.take(20).toList();
          _isUploading = false;
        });
      },
      onError: (err) {
        debugPrint(err);
        setState(() => _isUploading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PickPic")),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : GalleryImageGrid(filterUuidList: _serverUuidList),
    );
  }
}