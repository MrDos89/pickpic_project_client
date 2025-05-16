// main.dart
import 'package:flutter/material.dart';
import 'package:pickpic_project_client/page/intro_page.dart';

void main() {
  runApp(MaterialApp(
    home: IntroPage(), // MainApp으로 진입은 IntroPage 내부에서 처리
  ));
}