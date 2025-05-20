import 'package:flutter/material.dart';

class AppTheme {
  static final Color primaryColor = const Color.fromARGB(255, 133, 152, 246);

  static final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
    useMaterial3: true,
  );

  static final ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}