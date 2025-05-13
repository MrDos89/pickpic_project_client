import 'package:flutter/material.dart';
import 'page/text_search_page.dart';
import 'page/image_search_page.dart';
import 'page/voice_search_page.dart';
import 'page/draw_search_page.dart';
import 'page/settings_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

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
      home: HomePage(toggleTheme: toggleTheme, themeMode: _themeMode),
    );
  }
}

class HomePage extends StatefulWidget {
  final void Function(ThemeMode) toggleTheme;
  final ThemeMode themeMode;

  HomePage({required this.toggleTheme, required this.themeMode});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  late List<Widget> pages;
  ThemeMode get currentThemeMode => widget.themeMode;

  @override
  void initState() {
    super.initState();
    pages = [
      TextSearchPage(),
      ImageSearchPage(),
      VoiceSearchPage(),
      DrawSearchPage(),
      Container(),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
              NavigationRailDestination(
                icon: Icon(Icons.mic),
                label: Text('음성으로 검색'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.brush),
                label: Text('그리기로 검색'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('설정'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: selectedIndex == 4
                ? SettingsPage(
              toggleTheme: (mode) {
                widget.toggleTheme(mode);
                setState(() {});
              },
              themeMode: currentThemeMode,
            )
                : pages[selectedIndex],
          ),
        ],
      ),
    );
  }
}