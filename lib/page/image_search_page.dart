import 'package:flutter/material.dart';

class ImageSearchPage extends StatefulWidget {
  @override
  _ImageSearchPageState createState() => _ImageSearchPageState();
}

class _ImageSearchPageState extends State<ImageSearchPage> {
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        ElevatedButton.icon(
          icon: Icon(Icons.upload_file),
          label: Text("이미지 업로드"),
          onPressed: () {
            // 이미지 선택 로직
          },
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
            itemCount: images.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= images.length) {
                return Center(child: CircularProgressIndicator());
              }
              return Card(child: Center(child: Text(images[index])));
            },
          ),
        ),
      ],
    );
  }
}
