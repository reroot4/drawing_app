import 'package:flutter/material.dart';
import 'main_home_page.dart';
import 'app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PiLink System',
      theme: AppTheme.theme,
      home: const MainHomePage(),
    );
  }
}
