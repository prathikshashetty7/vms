import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemTheme {
  // Shared Colors
  static const Color background = Colors.white;
  static const Color primary = Color(0xFFC0C9EE); // Used by dept/receptionist
  static const Color secondary = Color(0xFFA2AADB); // Used by dept/receptionist
  static const Color accent = Color(0xFF898AC4); // Used by dept/receptionist
  static const Color text = Colors.black;

  // Design System Colors
  static const Color dsPrimary = Color(0xFF2563EB);
  static const Color dsSecondary = Color(0xFF3B82F6);
  static const Color dsAccent = Color(0xFF60A5FA);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color dsBackground = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient deptGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
  static const LinearGradient receptionistGradient = deptGradient;

  // Text Styles (Dept/Receptionist)
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

  // Design System Typography
  static TextStyle get heading1 => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );
  static TextStyle get heading2 => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );
  static TextStyle get heading3 => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );
  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );
  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );
  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.5,
  );

  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Shadows
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: dsPrimary,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: spacing24,
      vertical: spacing12,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
    elevation: 0,
  );
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: surface,
    foregroundColor: dsPrimary,
    padding: const EdgeInsets.symmetric(
      horizontal: spacing24,
      vertical: spacing12,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      side: const BorderSide(color: dsPrimary),
    ),
    elevation: 0,
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: textTertiary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: textTertiary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: dsPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing16,
      ),
    );
  }

  // Card Style
  static BoxDecoration cardDecoration = BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: textTertiary.withOpacity(0.2)),
    boxShadow: shadowSmall,
  );

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Page Transitions
  static PageRouteBuilder<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: animationNormal,
    );
  }
  static PageRouteBuilder<T> slideTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: animationNormal,
    );
  }

  // Background Gradient for Dept/Receptionist
  static BoxDecoration backgroundGradient = const BoxDecoration(
    gradient: deptGradient,
  );
} 