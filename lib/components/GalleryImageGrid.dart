import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

class GalleryImageGrid extends StatefulWidget {
  @override
  _GalleryImageGridState createState() => _GalleryImageGridState();
}

class _GalleryImageGridState extends State<GalleryImageGrid> {
  final ScrollController _scrollController = ScrollController();
  List<AssetEntity> _images = [];
  late AssetPathEntity _path;
  int _page = 0;
  final int _pageSize = 30;
  bool _isLoading = false;
  bool _hasMore = true;

  bool _hasRequestedPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoad();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _requestPermissionAndLoad() async {
    if (_hasRequestedPermission) return;
    _hasRequestedPermission = true;

    final result = await PhotoManager.requestPermissionExtend();
    debugPrint("🔍 요청 결과: ${result.isAuth}, details: $result");

    if (result.isAuth) {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isEmpty) {
        debugPrint("📂 앨범 없음. 권한은 있으나 불러올 이미지 없음");
        return;
      }

      _path = albums.first;
      _loadMore();
    } else {
      debugPrint("⚠️ 권한이 실제로 없음 또는 잘못된 판단 → 설정 페이지 이동");
      PhotoManager.openSetting();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 && !_isLoading && _hasMore) {
      _loadMore();
    }
  }

  void _loadMore() async {
    setState(() => _isLoading = true);
    final newAssets = await _path.getAssetListPaged(page: _page, size: _pageSize);
    setState(() {
      _images.addAll(newAssets);
      _isLoading = false;
      _hasMore = newAssets.length == _pageSize;
      _page++;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: _images.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _images.length) {
          return Center(child: CircularProgressIndicator());
        }
        return FutureBuilder<Uint8List?>(
          future: _images[index].thumbnailDataWithSize(ThumbnailSize(200, 200)),
          builder: (_, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            } else {
              return Container(color: Colors.grey[300]);
            }
          },
        );
      },
    );
  }
}