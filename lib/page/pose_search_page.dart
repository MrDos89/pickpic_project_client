import 'package:flutter/material.dart';
import 'package:pickpic_project_client/components/gallery_image_grid.dart';
import 'package:pickpic_project_client/components/image_uploader.dart';

class PoseSearchPage extends StatefulWidget {
  const PoseSearchPage({Key? key}) : super(key: key);

  @override
  State<PoseSearchPage> createState() => _PoseSearchPageState();
}

class _PoseSearchPageState extends State<PoseSearchPage> {
  final List<String> poses = [
    '만세 포즈', '손 흔들기 포즈', '팔 벌리기 포즈', '두 손 허리 포즈',
    '손 모으기 포즈', '점프샷 포즈', '서있는 포즈', '앉은 포즈',
    '런지/스트레칭 포즈', '누워있는 포즈'
  ];

  String? _selectedPose;

  @override
  Widget build(BuildContext context) {
    return _selectedPose == null
        ? _buildPoseFolderView()
        : _buildPoseImageView(_selectedPose!);
  }

  Widget _buildPoseFolderView() {
    return Scaffold(
      appBar: AppBar(title: Text("포즈 선택")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: poses.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => setState(() => _selectedPose = poses[index]),
            child: Column(
              children: [
                Icon(Icons.folder, size: 64, color: Colors.orange),
                SizedBox(height: 8),
                Text(poses[index], textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPoseImageView(String pose) {
    final uuidList = ImageUploader.getUuidListForPose(pose); // ➤ 구현 필요

    return Scaffold(
      appBar: AppBar(
        title: Text('$pose 사진 목록'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedPose = null),
        ),
      ),
      body: GalleryImageGrid(
        filterUuidList: uuidList,
      ),
    );
  }
}
