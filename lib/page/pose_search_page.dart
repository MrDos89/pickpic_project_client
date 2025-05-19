import 'package:flutter/material.dart';
import 'package:pickpic_project_client/components/gallery_image_grid.dart';
import 'package:pickpic_project_client/components/image_uploader.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  static const Map<String, String> _poseKorToKeyword = {
    '만세 포즈': '만세',
    '점프샷 포즈': '점프',
    '서있는 포즈': '서있음',
    '앉은 포즈': '앉음',
    '브이 손동작 포즈': '브이',
    '하트 손동작 포즈': '하트',
    '최고 손동작 포즈': '최고',
  };

  String? _selectedPose;
  List<String> _filteredUuidList = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return _selectedPose == null
        ? _buildPoseFolderView()
        : _buildPoseImageView(_selectedPose!);
  }

  Widget _buildPoseFolderView() {
    return Scaffold(
      appBar: AppBar(title: const Text("포즈 선택")),
      body: Stack(
        children: [
          GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: poses.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final pose = poses[index];
              final icon = poseIcons[pose] ?? Icon(Icons.folder);

              return GestureDetector(
                onTap: () => _onPoseTap(pose),
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
                      child: Center(child: icon),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pose,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _onPoseTap(String pose) async {
    final keyword = _poseKorToKeyword[pose] ?? pose.replaceAll(' 포즈', '');
    debugPrint("📡 [$pose] → pose 키워드 전송: $keyword");

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.247:8080/data/pose/test"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pose": keyword}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final uuidList = list
            .whereType<String>()
            .map((e) => e.replaceAll('.jpg', ''))
            .toList();

        final matched = uuidList.where((u) => ImageUploader.uuidAssetMap.containsKey(u)).length;
        debugPrint("🎯 매칭된 이미지 수: $matched");

        if (matched == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("📭 해당 포즈에 일치하는 이미지가 없습니다.")),
          );
        } else {
          setState(() {
            _filteredUuidList = uuidList;
            _selectedPose = pose;
          });
        }
      } else {
        debugPrint("❌ $pose fetch 실패: ${response.statusCode} ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ 서버 응답 실패: ${response.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("❌ 예외 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ 요청 중 오류 발생: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPoseImageView(String pose) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$pose 사진 목록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedPose = null),
        ),
      ),
      body: GalleryImageGrid(filterUuidList: _filteredUuidList),
    );
  }
}