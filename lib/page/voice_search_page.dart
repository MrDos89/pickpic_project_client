import 'package:flutter/material.dart';

class VoiceSearchPage extends StatefulWidget {
  @override
  _VoiceSearchPageState createState() => _VoiceSearchPageState();
}

class _VoiceSearchPageState extends State<VoiceSearchPage> {
  String result = "";

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                result = "사용자가 말한 텍스트";
              });
            },
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(40),
            ),
            child: Icon(Icons.mic, size: 40),
          ),
          SizedBox(height: 20),
          Text(result),
        ],
      ),
    );
  }
}