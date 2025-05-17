import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import 'package:pickpic_project_client/components/image_uploader.dart';

class GalleryImageGrid extends StatefulWidget {
  final List<String>? filterUuidList;
  final int crossAxisCount;

  const GalleryImageGrid({
    super.key,
    this.filterUuidList,
    this.crossAxisCount = 3,
  });

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

  @override
  void didUpdateWidget(covariant GalleryImageGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ 컬럼 수 변경 시 전체 리로드
    if (oldWidget.crossAxisCount != widget.crossAxisCount && widget.filterUuidList == null) {
      _resetAndReload();
    }

    // ✅ 필터 리스트가 변경되었을 때 다시 필터링
    final oldSet = oldWidget.filterUuidList?.toSet() ?? {};
    final newSet = widget.filterUuidList?.toSet() ?? {};
    if (oldSet.length != newSet.length || !oldSet.containsAll(newSet)) {
      if (widget.filterUuidList != null) {
        final filteredAssets = ImageUploader.filterAssetsByUuidList(widget.filterUuidList!);
        setState(() {
          _images = filteredAssets;
          _hasMore = false;
        });
      } else {
        _resetAndReload();
      }
    }
  }

  void _resetAndReload() {
    setState(() {
      _images.clear();
      _page = 0;
      _hasMore = true;
      _isLoading = false;
    });
    _loadMore();
  }

  Future<void> _requestPermissionAndLoad() async {
    if (_hasRequestedPermission) return;
    _hasRequestedPermission = true;

    final result = await PhotoManager.requestPermissionExtend();
    debugPrint("🔍 권한 요청 결과: ${result.isAuth}");

    if (result.isAuth) {
      await ImageUploader.prepareAllImages();

      if (widget.filterUuidList != null) {
        final filteredAssets = ImageUploader.filterAssetsByUuidList(widget.filterUuidList!);
        setState(() {
          _images = filteredAssets;
          _hasMore = false;
        });
      } else {
        final albums = await PhotoManager.getAssetPathList(
          type: RequestType.image,
          onlyAll: true,
        );

        if (albums.isEmpty) {
          debugPrint("📂 앨범 없음");
          return;
        }

        _path = albums.first;
        _loadMore();
      }
    } else {
      debugPrint("⚠️ 권한 없음 → 설정으로 이동");
      PhotoManager.openSetting();
    }
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 100 && !_isLoading && _hasMore) {
      debugPrint("🚀 스크롤 끝 근처 → 로드 추가");
      _loadMore();
    }
  }

  void _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);
    debugPrint("📦 [_loadMore] page $_page");

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
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _images.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _images.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return FutureBuilder<Uint8List?>(
          future: _images[index].thumbnailDataWithSize(const ThumbnailSize(200, 200)),
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
