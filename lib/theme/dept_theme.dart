import 'package:flutter/material.dart';

class DeptTheme {
  static const Color background = Colors.white;
  static const Color primary = Color(0xFFC0C9EE);
  static const Color secondary = Color(0xFFA2AADB);
  static const Color accent = Color(0xFF898AC4);
  static const Color text = Colors.black;

  static const LinearGradient deptGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      secondary,
    ],
  );

  static const TextStyle heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: text,
    letterSpacing: 1.2,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: accent,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: text,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: text,
    letterSpacing: 1.1,
  );

  static BoxDecoration backgroundGradient = const BoxDecoration(
    gradient: deptGradient,
  );
} 