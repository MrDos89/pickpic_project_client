import 'package:flutter/material.dart';
import 'package:pickpic_project_client/components/gallery_image_grid.dart';
import 'package:pickpic_project_client/components/image_uploader.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PoseSearchPage extends StatefulWidget {
  const PoseSearchPage({Key? key}) : super(key: key);

  @override
  State<PoseSearchPage> createState() => _PoseSearchPageState();
}

class _PoseSearchPageState extends State<PoseSearchPage> {
  final List<String> poses = [
    '만세 포즈', '점프샷 포즈', '서있는 포즈', '앉은 포즈', '브이 손동작 포즈', '하트 손동작 포즈', '최고 손동작 포즈',
  ];

  final Map<String, Widget> poseIcons = {
    '만세 포즈': Icon(Icons.emoji_people, size: 48, color: Colors.deepPurple),
    '점프샷 포즈': Icon(Icons.airline_stops, size: 48, color: Colors.deepPurple),
    '서있는 포즈': Icon(Icons.accessibility, size: 48, color: Colors.deepPurple),
    '앉은 포즈': Icon(Icons.event_seat, size: 48, color: Colors.deepPurple),
    '브이 손동작 포즈': FaIcon(FontAwesomeIcons.handPeace, size: 48, color: Colors.deepPurple),
    '하트 손동작 포즈': Icon(Icons.favorite, size: 48, color: Colors.deepPurple),
    '최고 손동작 포즈': Icon(Icons.thumb_up, size: 48, color: Colors.deepPurple),
  };

  String? _selectedPose;
  Map<String, List<String>> poseUuidMap = {};

  @override
  void initState() {
    super.initState();
    _loadPoseImages();
  }

  Future<void> _loadPoseImages() async {
    for (final pose in poses) {
      final uuidList = ImageUploader.poseToUuidListMap[pose] ?? [];
      poseUuidMap[pose] = uuidList;
      final matched = uuidList.where((u) => ImageUploader.uuidAssetMap.containsKey(u)).length;
      debugPrint("📌 $pose: 총 ${uuidList.length}개 중 $matched개가 uuidAssetMap에 존재");
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
          final count = uuidList.length;
          final icon = poseIcons[pose] ?? Icons.folder;

          return GestureDetector(
            onTap: () => setState(() => _selectedPose = pose),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: Center(
                    child: poseIcons[pose] ?? Icon(Icons.folder),
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
