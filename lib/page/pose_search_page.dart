import 'package:flutter/material.dart';
import 'package:pickpic_project_client/components/GalleryImageGrid.dart';

class PoseSearchPage extends StatefulWidget {
  const PoseSearchPage({Key? key}) : super(key: key);

  @override
  State<PoseSearchPage> createState() => _PoseSearchPageState();
}

class _PoseSearchPageState extends State<PoseSearchPage> {
  final ScrollController _scrollController = ScrollController();
  List<String> _photos = List.generate(20, (index) => '사진 $index');
  bool _isLoading = false;

  final List<String> poses = [
    '만세 포즈',
    '손 흔들기 포즈',
    '팔 벌리기 포즈',
    '두 손 허리 포즈',
    '손 모으기 포즈',
    '점프샷 포즈',
    '서있는 포즈',
    '앉은 포즈',
    '런지/스트레칭 포즈',
    '누워있는 포즈'
  ];

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("포즈 선택", style: Theme.of(context).textTheme.titleMedium),
                    Icon(Icons.swipe, size: 20, color: Colors.grey),
                  ],
                ),
              ),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: poses.length,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) => Card(
                    margin: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        // TODO: 포즈별 검색 기능 연결
                      },
                      child: Container(
                        width: 100,
                        padding: EdgeInsets.all(10),
                        alignment: Alignment.center,
                        child: Text(
                          poses[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
