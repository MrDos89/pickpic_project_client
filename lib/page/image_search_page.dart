import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:http/http.dart' as http;
import 'package:pickpic_project_client/components/gallery_image_grid.dart';
import 'package:pickpic_project_client/components/image_uploader.dart';
import 'package:pickpic_project_client/page/loading_overlay.dart';

class ImageSearchPage extends StatefulWidget {
  final int crossAxisCount;

  const ImageSearchPage({Key? key, this.crossAxisCount = 3}) : super(key: key);

  @override
  _ImageSearchPageState createState() => _ImageSearchPageState();
}

class _ImageSearchPageState extends State<ImageSearchPage> {
  List<String>? _filteredUuidList;

  Future<void> _onImageTap(String uuid) async {
    final imageName = "$uuid.jpg";
    LoadingOverlay.show(context, message: "이미지로 유사 이미지 검색 중...");

    try {
      final response = await http.post(
        Uri.parse("http://192.168.0.247:8080/data/img2img/test"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image_name": imageName}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is List) {
          final filenames = json
              .whereType<String>()
              .map((f) => f.replaceAll('.jpg', ''))
              .toList();

          setState(() {
            _filteredUuidList = filenames;
          });
        } else {
          debugPrint("❌ 예상치 못한 응답 구조: $json");
        }
      } else {
        debugPrint("❌ 서버 응답 오류: ${response.statusCode}, ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ 요청 실패: $e");
    } finally {
      LoadingOverlay.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAssets = ImageUploader.uuidAssetMap.entries.toList();

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text("이미지를 선택하면 유사한 이미지를 검색합니다."),
        const SizedBox(height: 12),
        Expanded(
          child: _filteredUuidList == null
              ? GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.crossAxisCount,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: allAssets.length,
            itemBuilder: (context, index) {
              final uuid = allAssets[index].key;
              final asset = allAssets[index].value;

              return FutureBuilder<Uint8List?>(
                future: asset.thumbnailDataWithSize(
                    const ThumbnailSize(200, 200)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData &&
                      snapshot.data != null) {
                    return GestureDetector(
                      onTap: () => _onImageTap(uuid),
                      child: Image.memory(snapshot.data!,
                          fit: BoxFit.cover),
                    );
                  } else {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                },
              );
            },
          )
              : GalleryImageGrid(
            filterUuidList: _filteredUuidList,
            crossAxisCount: widget.crossAxisCount,
          ),
        ),
      ],
    );
  }
}
