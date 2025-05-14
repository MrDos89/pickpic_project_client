import 'package:flutter/material.dart';
import 'package:pickpic_project_client/components/gallery_image_grid.dart';

class DrawSearchPage extends StatefulWidget {
  @override
  _DrawSearchPageState createState() => _DrawSearchPageState();
}

class _DrawSearchPageState extends State<DrawSearchPage> {
  Image? drawnImage;

  final ScrollController _scrollController = ScrollController();
  List<String> images = List.generate(20, (index) => '사진 $index');
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && !isLoading) {
      _loadMore();
    }
  }

  void _loadMore() async {
    setState(() => isLoading = true);
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      images.addAll(List.generate(20, (index) => '사진 ${images.length + index}'));
      isLoading = false;
    });
  }

  void _openDrawingModal() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Container(
          width: 300,
          height: 300,
          color: Colors.white,
          child: GestureDetector(
            onPanUpdate: (details) {
              // 그림 그리기 로직
            },
            child: Center(child: Text("그림 그리는 영역")),
          ),
        ),
        actions: [
          TextButton(
            child: Text("확인"),
            onPressed: () {
              setState(() {
                drawnImage = Image.asset('assets/drawn_result.png');
              });
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Center(
          child: drawnImage != null
              ? drawnImage!
              : ElevatedButton(
            child: Text("그리기"),
            onPressed: _openDrawingModal,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: () {}, child: Text("검색")),
        const SizedBox(height: 20),
        Expanded(
          // child: GridView.builder(
          //   controller: _scrollController,
          //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          //   itemCount: images.length + (isLoading ? 1 : 0),
          //   itemBuilder: (context, index) {
          //     if (index >= images.length) {
          //       return Center(child: CircularProgressIndicator());
          //     }
          //     return Card(child: Center(child: Text(images[index])));
          //   },
          // ),
          child: GalleryImageGrid(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
