import 'package:flutter/material.dart';
import 'package:pickpic_project_client/page/intro_page.dart';
import 'package:pickpic_project_client/main_app.dart';

void main() {
  runApp(MyBootstrapApp());
}

class MyBootstrapApp extends StatefulWidget {
  @override
  State<MyBootstrapApp> createState() => _MyBootstrapAppState();
}

class _MyBootstrapAppState extends State<MyBootstrapApp> {
  bool _permissionGranted = false;

  void _onPermissionsGranted() {
    setState(() {
      _permissionGranted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _permissionGranted
          ? MainApp() // 실제 앱 UI 진입
          : IntroPage(onPermissionGranted: _onPermissionsGranted),
    );
  }
}