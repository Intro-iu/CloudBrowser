import 'package:flutter/material.dart';
import 'package:CloudBrowser/pages/home_page.dart'; 
import 'package:CloudBrowser/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CloudBrowser',
      theme: AppTheme.lightTheme, // 确保已正确导入 AppTheme
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}