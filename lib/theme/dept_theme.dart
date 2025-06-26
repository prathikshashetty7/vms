import 'package:flutter/material.dart';

class DeptTheme {
  // Gradient colors for department screens
  static const Color deptPrimary = Color(0xFF4F8A8B);
  static const Color deptSecondary = Color(0xFF72C3DC);
  static const Color deptAccent = Color(0xFFB5EAEA);
  static const Color deptDark = Color(0xFF254E58);
  static const Color deptLight = Color(0xFFEFF6F7);

  static const LinearGradient deptGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      deptPrimary,
      deptSecondary,
      deptAccent,
    ],
  );

  static const TextStyle heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: deptDark,
    letterSpacing: 1.2,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: deptPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: deptDark,
  );

  static BoxDecoration backgroundGradient = const BoxDecoration(
    gradient: deptGradient,
  );
} 