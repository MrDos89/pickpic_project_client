import 'package:flutter/material.dart';
import 'package:pickpic_project_client/components/GalleryImageGrid.dart';

class TextSearchPage extends StatefulWidget {
  @override
  _TextSearchPageState createState() => _TextSearchPageState();
}

class _TextSearchPageState extends State<TextSearchPage> {
  final ScrollController _scrollController = ScrollController();
  List<String> _photos = List.generate(20, (index) => '사진 $index');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoading) {
      _loadMore();
    }
  }

  void _loadMore() async {
    setState(() => _isLoading = true);
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _photos.addAll(List.generate(20, (index) => '사진 ${_photos.length + index}'));
      _isLoading = false;
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: '검색어 입력'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () {}, child: Text('검색')),
            ],
          ),
        ),
        Expanded(
          // child: GridView.builder(
          //   controller: _scrollController,
          //   padding: EdgeInsets.all(8),
          //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //     crossAxisCount: 3,
          //     crossAxisSpacing: 8,
          //     mainAxisSpacing: 8,
          //   ),
          //   itemBuilder: (context, index) => Container(
          //     color: Colors.grey[300],
          //     alignment: Alignment.center,
          //     child: Text(_photos[index]),
          //   ),
          //   itemCount: _photos.length,
          // ),
          child: GalleryImageGrid(),
        ),
        if (_isLoading) Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        )
      ],
    );
  }
}
