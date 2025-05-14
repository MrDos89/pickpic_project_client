import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io'; // 플랫폼 분기용

class IntroPage extends StatefulWidget {
  final VoidCallback onPermissionGranted;
  const IntroPage({super.key, required this.onPermissionGranted});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap(BuildContext context) async {
    // 권한 상태 먼저 확인
    final photoStatus = await Permission.photos.status;
    final micStatus = await Permission.microphone.status;

    // permanentlyDenied인 경우 설정화면 유도
    if (photoStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("권한 설정 필요"),
          content: const Text("권한이 영구적으로 거부되었습니다.\n설정에서 수동으로 허용해주세요."),
          actions: [
            TextButton(
              onPressed: () {
                openAppSettings(); // 앱 설정으로 이동
                Navigator.of(context).pop();
              },
              child: const Text("설정으로 이동"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("취소"),
            ),
          ],
        ),
      );
      return;
    }

    // 일반적인 요청 (거절 상태 포함)
    final statuses = await [
      Permission.photos,
      Permission.microphone,
    ].request();

    final allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      widget.onPermissionGranted(); // ✅ MainApp 진입
    } else {
      // ❌ 거절 상태일 경우 재요청 가능
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("권한 부족"),
          content: const Text("사진 및 음성 접근 권한이 모두 필요합니다.\n다시 시도해주세요."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("확인"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "PickPic",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 30),
              AnimatedBuilder(
                animation: _opacity,
                builder: (context, child) => Opacity(
                  opacity: _opacity.value,
                  child: Text(
                    "Tap to Enter",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurpleAccent,
                      shadows: [
                        Shadow(
                          color: Colors.deepPurpleAccent.withOpacity(0.6),
                          blurRadius: 12,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}