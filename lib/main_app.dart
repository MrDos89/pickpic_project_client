// main_app.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pickpic_project_client/components/image_uploader.dart';
import 'page/text_search_page.dart';
import 'page/image_search_page.dart';
import 'page/voice_search_page.dart';
import 'page/draw_search_page.dart';
import 'page/pose_search_page.dart';
import 'page/settings_page.dart';
import 'package:http/http.dart' as http;

class MainApp extends StatefulWidget {
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.light;
  int _gridColumnCount = 3; // ✅ 추가

  void toggleTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void setGridColumnCount(int count) {
    setState(() {
      _gridColumnCount = count;
    });
  }

  @override
  void initState() {
    super.initState();
    _initUploadFlow();
  }

  Future<void> _initUploadFlow() async {
    await ImageUploader.prepareAllImages();
    await ImageUploader.compressAndUploadMappedImages(
      uploadUrl: "http://localhost:8080/upload",
      onSuccess: (msg) => debugPrint(msg),
      onError: (err) => debugPrint("업로드 실패: \$err"),
    );
  }

  // Future<void> _initUploadFlow() async {
  //   await ImageUploader.prepareAllImages();
  //
  //   await ImageUploader.uploadToCloudStorage(
  //     getSignedUrl: (uuid) async {
  //       final response = await http.get(
  //         Uri.parse('https://your.api/signed-url/$uuid'),
  //       );
  //
  //       if (response.statusCode == 200) {
  //         return response.body;
  //       } else {
  //         throw Exception('Signed URL 요청 실패 (uuid: $uuid)');
  //       }
  //     },
  //     onSuccess: (msg) => debugPrint(msg),
  //     onError: (err) => debugPrint("업로드 실패: $err"),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PickPic',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.deepPurple,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primarySwatch: Colors.deepPurple,
      ),
      themeMode: _themeMode,
      home: HomePage(
        toggleTheme: toggleTheme,
        themeMode: _themeMode,
        gridColumnCount: _gridColumnCount,
        setGridColumnCount: setGridColumnCount,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final void Function(ThemeMode) toggleTheme;
  final ThemeMode themeMode;
  final int gridColumnCount;
  final void Function(int) setGridColumnCount;

  HomePage({
    required this.toggleTheme,
    required this.themeMode,
    required this.gridColumnCount,
    required this.setGridColumnCount,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    pages = [
      TextSearchPage(crossAxisCount: widget.gridColumnCount),
      ImageSearchPage(crossAxisCount: widget.gridColumnCount),
      VoiceSearchPage(crossAxisCount: widget.gridColumnCount),
      DrawSearchPage(crossAxisCount: widget.gridColumnCount),
      PoseSearchPage(crossAxisCount: widget.gridColumnCount),
      Container(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text("PickPic")),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.text_fields),
                label: Text('텍스트로 검색'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.image),
                label: Text('이미지로 검색'),
              ),
              // ...
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('설정'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: selectedIndex == 2
                ? SettingsPage(
              toggleTheme: widget.toggleTheme,
              themeMode: widget.themeMode,
              currentGridCount: widget.gridColumnCount,
              onGridCountChanged: widget.setGridColumnCount,
            )
                : pages[selectedIndex],
          ),
        ],
      ),
    );
  }
}
