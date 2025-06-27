import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  // Color Palette
  static const Color iceWhite = Color(0xFFF0FBFA); // #F0FBFA
  static const Color lightBlue = Color(0xFFC0E4ED); // #C0E4ED
  static const Color mediumBlue = Color(0xFF87A9D6); // #87A9D6
  static const Color darkBlue = Color(0xFF576D89); // #576D89
  static const Color deepBlue = Color(0xFF081735); // #081735

  // Status Colors
  static const Color success = Color(0xFF22C55E); // green
  static const Color warning = Color(0xFFF59E0B); // yellow
  static const Color error = Color(0xFFEF4444);   // red
  static const Color info = Color(0xFF3B82F6);    // blue

  // Backgrounds & Surfaces
  static const Color background = iceWhite;
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // Text Colors
  static const Color textPrimary = deepBlue;
  static const Color textSecondary = darkBlue;
  static const Color textTertiary = mediumBlue;

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

  // Typography
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

  // Interactive Card Styles
  static BoxDecoration interactiveCardDecoration = BoxDecoration(
    color: iceWhite,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: mediumBlue.withOpacity(0.2)),
    boxShadow: [
      BoxShadow(
        color: mediumBlue.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration hoverCardDecoration = BoxDecoration(
    color: lightBlue,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: mediumBlue.withOpacity(0.3)),
    boxShadow: [
      BoxShadow(
        color: mediumBlue.withOpacity(0.1),
        blurRadius: 15,
        offset: const Offset(0, 6),
      ),
    ],
  );

  // Status Badge Styles
  static BoxDecoration statusBadgeDecoration(Color color) => BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: color.withOpacity(0.2)),
  );

  // Interactive Button Styles
  static ButtonStyle primaryInteractiveButton = ElevatedButton.styleFrom(
    backgroundColor: mediumBlue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 12,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
    shadowColor: mediumBlue.withOpacity(0.3),
  ).copyWith(
    overlayColor: MaterialStateProperty.resolveWith<Color?>(
      (Set<MaterialState> states) {
        if (states.contains(MaterialState.hovered)) {
          return mediumBlue.withOpacity(0.8);
        }
        return null;
      },
    ),
  );

  // Custom Gradients
  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      mediumBlue.withOpacity(0.8),
      darkBlue.withOpacity(0.8),
    ],
  );

  // Custom Input Styles
  static InputDecoration interactiveInputDecoration({
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
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkBlue.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: darkBlue.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: mediumBlue, width: 2),
      ),
      filled: true,
      fillColor: iceWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );
  }

  // Shadows
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: deepBlue.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: deepBlue.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: deepBlue.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Card Style
  static BoxDecoration cardDecoration = BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: textTertiary.withOpacity(0.2)),
    boxShadow: shadowSmall,
  );

  static const Color primary = mediumBlue;
  static const Color secondary = lightBlue;

  static const Color mountainDark = Color(0xFF2E4255);
  static const Color mountainGray = Color(0xFF8599AB);
  static const Color mountainLight = Color(0xFFA8B5C2);
  static const Color mountainPale = Color(0xFFD5D6D6);
  static const Color mountainBlue = Color(0xFF8FA3BC);

  static LinearGradient mountainBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      mountainDark,
      mountainGray,
      mountainLight,
      mountainPale,
      mountainBlue,
    ],
  );

  static const Color midnight = Color(0xFF030712);
  static const Color oceanBlue = Color(0xFF0c3460);
  static const Color royalBlue = Color(0xFF1e498b);
  static const Color skyBlue = Color(0xFF6894c2);

  static const Color textLight = Colors.white;
  static const Color textDark = midnight;

  static LinearGradient adminBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [midnight, deepBlue, oceanBlue, royalBlue],
  );
} 