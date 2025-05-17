import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pickpic_project_client/components/gallery_image_grid.dart';
import 'package:pickpic_project_client/page/loading_overlay.dart';

class TextSearchPage extends StatefulWidget {
  final int crossAxisCount;

  const TextSearchPage({Key? key, this.crossAxisCount = 3}) : super(key: key);

  @override
  _TextSearchPageState createState() => _TextSearchPageState();
}

class _TextSearchPageState extends State<TextSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<String>? _searchUuidList; // null: 전체, empty: 결과 없음
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // 무한 스크롤 기능 필요 시 추가
    }
  }

  Future<void> _performSearch() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _searchUuidList = null;
        _errorMessage = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    LoadingOverlay.show(context, message: "검색 중...");

    setState(() {
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.248:8080/data/txt2img'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ssid': 'test',
          'keyword': keyword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['results'] is List) {
          final results = data['results'] as List;
          final filenames = results
              .map((item) => item['filename'])
              .whereType<String>()
              .map((filename) => filename.replaceAll('.jpg', '').replaceAll('.jpeg', '').replaceAll('.png', ''))
              .toList();

          setState(() {
            _searchUuidList = filenames;
          });
        } else {
          setState(() {
            _errorMessage = '서버 응답 형식이 잘못되었습니다.';
            _searchUuidList = null;
          });
        }
      } else {
        setState(() {
          _errorMessage = '검색에 실패했습니다. (${response.statusCode})';
          _searchUuidList = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '네트워크 오류가 발생했습니다.';
        _searchUuidList = null;
      });
      debugPrint("❌ 예외 발생: $e");
    } finally {
      LoadingOverlay.hide(context);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isResultEmpty = _searchUuidList != null && _searchUuidList!.isEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: '검색어 입력'),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _performSearch, child: const Text('검색')),
                ],
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: isResultEmpty
              ? const Center(
            child: Text(
              '검색 결과가 없습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          )
              : GalleryImageGrid(
            crossAxisCount: widget.crossAxisCount,
            filterUuidList: _searchUuidList,
          ),
        ),
      ],
    );
  }
}
