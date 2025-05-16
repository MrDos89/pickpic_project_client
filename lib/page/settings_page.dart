import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final void Function(ThemeMode) toggleTheme;
  final ThemeMode themeMode;

  const SettingsPage({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("테마 설정", style: Theme.of(context).textTheme.titleLarge),
          ListTile(
            title: const Text("라이트 모드"),
            leading: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeMode,
              onChanged: (value) => toggleTheme(value!),
            ),
          ),
          ListTile(
            title: const Text("다크 모드"),
            leading: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeMode,
              onChanged: (value) => toggleTheme(value!),
            ),
          ),
        ],
      ),
    );
  }
}