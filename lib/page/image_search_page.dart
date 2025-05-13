import 'package:flutter/material.dart';

class ImageSearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: Icon(Icons.upload_file),
        label: Text("이미지 업로드"),
        onPressed: () {
          // 이미지 선택 로직
        },
      ),
    );
  }
}