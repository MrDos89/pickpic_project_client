import 'package:flutter/material.dart';

class DrawSearchPage extends StatefulWidget {
  @override
  _DrawSearchPageState createState() => _DrawSearchPageState();
}

class _DrawSearchPageState extends State<DrawSearchPage> {
  Image? drawnImage;

  void _openDrawingModal() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Container(
          width: 300,
          height: 300,
          color: Colors.white,
          child: GestureDetector(
            onPanUpdate: (details) {
              // 그림 그리기 로직
            },
            child: Center(child: Text("그림 그리는 영역")),
          ),
        ),
        actions: [
          TextButton(
            child: Text("확인"),
            onPressed: () {
              setState(() {
                drawnImage = Image.asset('assets/drawn_result.png');
              });
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: drawnImage != null
              ? drawnImage!
              : ElevatedButton(
            child: Text("그리기"),
            onPressed: _openDrawingModal,
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(onPressed: () {}, child: Text("검색"))
      ],
    );
  }
}
