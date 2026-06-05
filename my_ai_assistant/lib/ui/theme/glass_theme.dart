import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aether AI Design System (Premium Glassmorphism - Abyssal Minimal)
/// Based on Stitch Conversational Task Planner reference.

class GlassColors {
  // Abyssal Minimal Palette
  static const Color background = Color(0xFF0F1418);
  static const Color surface = Color(0xFF1B2024);
  static const Color surfaceBright = Color(0xFF353A3E);
  static const Color surfaceContainer = Color(0xFF1B2024);
  static const Color surfaceHighest = Color(0xFF30353A);
  static const Color primary = Color(0xFFCCDEE7);
  static const Color onPrimary = Color(0xFF22333A);
  static const Color secondary = Color(0xFFBDC8D4);
  static const Color tertiary = Color(0xFFCDDDE9);
  static const Color gold = Color(0xFFCC9E67); // Muted Gold from DESIGN.md
  
  static const Color onSurface = Color(0xFFDFE3E9);
  static const Color onSurfaceVariant = Color(0xFFC3C7CA);
  static const Color outline = Color(0xFF8D9194);
  static const Color outlineVariant = Color(0xFF43474A);
  
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFFFB4AB);

  // Exact Glass Tokens from Reference
  static Color glassSurface = const Color(0xFF23323B).withOpacity(0.4); // rgba(35, 50, 59, 0.4)
  static Color ghostBorder = const Color(0xFFB0C2CB).withOpacity(0.1);  // rgba(176, 194, 203, 0.1)

  static Color glassBorder() => ghostBorder;
  static Color glassTint() => primary.withOpacity(0.05);

  // Task 25.2: Distinct Operative Identity
  static const List<Color> memberPalette = [
    Color(0xFF34D399), // success/green
    Color(0xFFCC9E67), // gold
    Color(0xFF60A5FA), // light blue
    Color(0xFFF87171), // red/error
    Color(0xFFA78BFA), // purple
    Color(0xFFF472B6), // pink
    Color(0xFFFB923C), // orange
    Color(0xFF2DD4BF), // teal
  ];

  static Color getMemberColor(String uid) {
    if (uid.isEmpty) return primary;
    final int hash = uid.codeUnits.fold(0, (prev, element) => prev + element);
    return memberPalette[hash % memberPalette.length];
  }
}

class ExecutiveSpacing {
  static const double unit = 8.0;
  static const double stackSm = 12.0;
  
  // Dynamic scaling based on screen size
  static double stackMd(BuildContext context) => 
      MediaQuery.of(context).size.width < 600 ? 16.0 : 32.0;
      
  static double gutter(BuildContext context) => 
      MediaQuery.of(context).size.width < 600 ? 12.0 : 24.0;
      
  static double containerPadding(BuildContext context) => 
      MediaQuery.of(context).size.width < 600 ? 16.0 : 64.0;
      
  static double sectionGap(BuildContext context) => 
      MediaQuery.of(context).size.width < 600 ? 48.0 : 160.0;

  // Legacy Aliases (Now Dynamic)
  static double get m => 16.0;
  static double get l => 24.0;
}


class ExecutiveRadius {
  static const double s = 2.0; // 0.125rem
  static const double m = 4.0; // 0.25rem
  static const double l = 6.0; // 0.375rem
  static const double xl = 8.0; // 0.5rem (Standard for Abyssal Minimal)
  static const double xxl = 12.0; // 0.75rem
  static const double circular = 9999.0;
}

class GlassGradients {
  static LinearGradient background() => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [GlassColors.background, Color(0xFF0A0F13)],
      );
}

class GlassDecorations {
  static BoxDecoration surface({bool isDark = true, double radius = 8, bool hasShadow = false}) => BoxDecoration(
        color: GlassColors.glassSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: GlassColors.ghostBorder, width: 1.0),
        boxShadow: hasShadow ? [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 12)),
        ] : [],
      );

  static BoxDecoration elevated({bool isDark = true, double radius = 16}) => BoxDecoration(
        color: GlassColors.glassSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: GlassColors.primary.withOpacity(0.2), width: 1.0),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
      );

  static BoxDecoration button({bool isDark = true, bool isGold = false}) {
    return BoxDecoration(
      color: isGold ? GlassColors.gold.withOpacity(0.1) : GlassColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
      border: Border.all(color: isGold ? GlassColors.gold.withOpacity(0.3) : GlassColors.primary.withOpacity(0.2), width: 1.0),
    );
  }

  static BoxDecoration ghostButton({bool isGold = false}) {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
      border: Border.all(color: GlassColors.outlineVariant.withOpacity(0.3), width: 1.0),
    );
  }
}

class GlassText {
  // Headlines (Newsreader)
  static TextStyle headlineXL() => GoogleFonts.newsreader(
    fontSize: 83, 
    fontWeight: FontWeight.w400, 
    color: GlassColors.primary, 
    letterSpacing: -0.02 * 83,
    height: 1.1,
  );
  
  static TextStyle headlineLG() => GoogleFonts.newsreader(
    fontSize: 38, 
    fontWeight: FontWeight.w400, 
    color: GlassColors.primary,
    height: 1.2,
  );

  static TextStyle headlineMD() => GoogleFonts.newsreader(
    fontSize: 24, 
    fontWeight: FontWeight.w400, 
    color: GlassColors.primary,
  );

  // Body & Labels (Work Sans)
  static TextStyle bodyLG() => GoogleFonts.workSans(
    fontSize: 21, 
    fontWeight: FontWeight.w400, 
    color: GlassColors.onSurface, 
    height: 1.6,
  );

  static TextStyle bodyMD() => GoogleFonts.workSans(
    fontSize: 14, 
    fontWeight: FontWeight.w400, 
    color: GlassColors.onSurface, 
    height: 1.6,
  );

  static TextStyle secondary() => GoogleFonts.workSans(
    fontSize: 14, 
    fontWeight: FontWeight.w400, 
    color: GlassColors.onSurfaceVariant,
    height: 1.6,
  );

  static TextStyle labelSM() => GoogleFonts.workSans(
    fontSize: 12, 
    fontWeight: FontWeight.w600, 
    color: GlassColors.onSurface, 
    letterSpacing: 0.1 * 12,
    height: 1.0,
  );
  
  // Legacy alias for compatibility
  static TextStyle headline([bool isDark = true]) => headlineLG();
  static TextStyle title([bool isDark = true]) => headlineMD();
  static TextStyle body([bool isDark = true]) => bodyMD();
  static TextStyle label([bool isDark = true]) => labelSM().copyWith(color: GlassColors.primary);
  static TextStyle caption([bool isDark = true]) => secondary().copyWith(fontSize: 12);
}