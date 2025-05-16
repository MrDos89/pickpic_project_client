import 'package:flutter/material.dart';
import 'package:pickpic_project_client/components/gallery_image_grid.dart';
import 'package:pickpic_project_client/components/image_uploader.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

class PoseSearchPage extends StatefulWidget {
  const PoseSearchPage({Key? key}) : super(key: key);

  @override
  State<PoseSearchPage> createState() => _PoseSearchPageState();
}

class _PoseSearchPageState extends State<PoseSearchPage> {
  final List<String> poses = [
    '만세 포즈', '점프샷 포즈', '서있는 포즈', '앉은 포즈',
    '누워있는 포즈', '브이 손동작 포즈', '하트 손동작 포즈', '최고 손동작 포즈',
  ];

  String? _selectedPose;
  Map<String, List<String>> poseUuidMap = {};
  Map<String, AssetEntity?> poseThumbnails = {};

  @override
  void initState() {
    super.initState();
    _loadPoseImages();
  }

  Future<void> _loadPoseImages() async {
    for (final pose in poses) {
      final uuidList = ImageUploader.poseToUuidListMap[pose] ?? [];
      poseUuidMap[pose] = uuidList;

      if (uuidList.isNotEmpty) {
        final asset = ImageUploader.uuidAssetMap[uuidList.first];
        poseThumbnails[pose] = asset;
      } else {
        poseThumbnails[pose] = null;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _selectedPose == null
        ? _buildPoseFolderView()
        : _buildPoseImageView(_selectedPose!);
  }

  Widget _buildPoseFolderView() {
    return Scaffold(
      appBar: AppBar(title: const Text("포즈 선택")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: poses.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final pose = poses[index];
          final uuidList = ImageUploader.poseToUuidListMap[pose] ?? [];
          final thumbnails = uuidList
              .map((uuid) => ImageUploader.uuidAssetMap[uuid])
              .whereType<AssetEntity>()
              .take(4)
              .toList();
          final count = uuidList.length;

          return GestureDetector(
            onTap: () => setState(() => _selectedPose = pose),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(2),
                  child: thumbnails.isEmpty
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.image, size: 40, color: Colors.grey),
                      SizedBox(height: 4),
                      Text(
                        'No Image',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  )
                      : GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: 4,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 1,
                      crossAxisSpacing: 1,
                    ),
                    itemBuilder: (context, i) {
                      if (i < thumbnails.length) {
                        return FutureBuilder<Uint8List?>(
                          future: thumbnails[i].thumbnailDataWithSize(
                              const ThumbnailSize(100, 100)),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done &&
                                snapshot.hasData &&
                                snapshot.data != null) {
                              return Image.memory(snapshot.data!, fit: BoxFit.cover);
                            } else {
                              return const SizedBox(); // 로딩 중에도 빈 공간
                            }
                          },
                        );
                      } else {
                        return const SizedBox(); // 썸네일 없으면 빈 공간
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$pose ($count)',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPoseImageView(String pose) {
    final uuidList = poseUuidMap[pose];

    return Scaffold(
      appBar: AppBar(
        title: Text('$pose 사진 목록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedPose = null),
        ),
      ),
      body: GalleryImageGrid(filterUuidList: uuidList),
    );
  }
}