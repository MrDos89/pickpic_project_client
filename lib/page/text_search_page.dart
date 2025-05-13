import 'package:flutter/material.dart';

class TextSearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: '검색어 입력'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: () {}, child: Text('검색')),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) => Container(
              color: Colors.grey[300],
              child: Icon(Icons.photo),
            ),
            itemCount: 9,
          ),
        )
      ],
    );
  }
}