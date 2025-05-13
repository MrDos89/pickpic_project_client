import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final void Function(ThemeMode) toggleTheme;
  final ThemeMode themeMode;

  SettingsPage({required this.toggleTheme, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("테마 설정", style: Theme.of(context).textTheme.titleLarge),
          ListTile(
            title: Text("라이트 모드"),
            leading: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) toggleTheme(value);
              },
            ),
          ),
          ListTile(
            title: Text("다크 모드"),
            leading: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) toggleTheme(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}