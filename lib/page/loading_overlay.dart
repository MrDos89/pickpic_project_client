import 'package:flutter/material.dart';

class LoadingOverlay {
  static void show(BuildContext context, {String message = "로딩 중입니다..."}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: _AnimatedLoadingDialog(message: message),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

class _AnimatedLoadingDialog extends StatefulWidget {
  final String message;
  const _AnimatedLoadingDialog({required this.message});

  @override
  State<_AnimatedLoadingDialog> createState() => _AnimatedLoadingDialogState();
}

class _AnimatedLoadingDialogState extends State<_AnimatedLoadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _opacity,
              child: Text(
                widget.message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepPurple, // ✅ 텍스트 색상
                  decoration: TextDecoration.none, // ✅ 밑줄 제거
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
