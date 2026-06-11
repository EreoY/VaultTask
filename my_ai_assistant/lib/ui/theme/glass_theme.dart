import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aether AI Design System (Notion-Style Minimalist Light Theme)
/// Adapted from React/Tailwind reference design.

class GlassColors {
  // Abyssal Minimal Palette
  static const Color background = Color(0xFF0F1418);
  static const Color surface = Color(0xFF181C20);
  static const Color surfaceBright = Color(0xFF24292E);
  static const Color surfaceContainer = Color(0xFF14181C);
  static const Color surfaceHighest = Color(0xFF2C3136);
  static const Color primary = Color(0xFFD7E5ED);
  static const Color onPrimary = Color(0xFF202C33);
  static const Color secondary = Color(0xFFC0CBD4);
  static const Color tertiary = Color(0xFFD2DDE6);
  static const Color gold = Color(0xFFCC9E67); // Muted Gold from DESIGN.md
  static const Color hairline = Color(0xFF2A2F34);
  static const Color hairlineStrong = Color(0xFF3A4046);
  static const Color muted = Color(0xFF8D949A);

  static const Color onSurface = Color(0xFFDFE3E9);
  static const Color onSurfaceVariant = Color(0xFFC3C7CA);
  static const Color outline = Color(0xFF8D9194);
  static const Color outlineVariant = Color(0xFF43474A);

  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFFFB4AB);

  // Exact Glass Tokens from Reference
  static Color glassSurface = const Color(
    0xFF23323B,
  ).withOpacity(0.4); // rgba(35, 50, 59, 0.4)
  static Color ghostBorder = const Color(
    0xFFB0C2CB,
  ).withOpacity(0.1); // rgba(176, 194, 203, 0.1)

  static Color glassBorder() => ghostBorder;
  static Color glassTint() => primary.withOpacity(0.05);

  // Distinct Operative Identity
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
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double stackSm = 12.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

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
  static const double s = 4.0;
  static const double m = 6.0;
  static const double l = 8.0;
  static const double xl = 12.0;
  static const double xxl = 12.0;
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
  static BoxDecoration surface({
    bool isDark = true,
    double radius = 8,
    bool hasShadow = false,
  }) => BoxDecoration(
    color: GlassColors.glassSurface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: GlassColors.ghostBorder, width: 1.0),
    boxShadow: hasShadow
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ]
        : [],
  );

  static BoxDecoration solidSurface({
    double radius = 8,
    bool hasShadow = false,
  }) => BoxDecoration(
    color: GlassColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: GlassColors.hairlineStrong.withOpacity(0.7),
      width: 1.0,
    ),
    boxShadow: hasShadow
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ]
        : [],
  );

  static BoxDecoration elevated({bool isDark = true, double radius = 16}) =>
      BoxDecoration(
        color: GlassColors.glassSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: GlassColors.primary.withOpacity(0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration button({bool isDark = true, bool isGold = false}) {
    return BoxDecoration(
      color: isGold
          ? GlassColors.gold.withOpacity(0.1)
          : GlassColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
      border: Border.all(
        color: isGold
            ? GlassColors.gold.withOpacity(0.3)
            : GlassColors.primary.withOpacity(0.2),
        width: 1.0,
      ),
    );
  }

  static BoxDecoration ghostButton({bool isGold = false}) {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
      border: Border.all(
        color: GlassColors.outlineVariant.withOpacity(0.3),
        width: 1.0,
      ),
    );
  }
}

class GlassText {
  // Headlines (Inter)
  static TextStyle headlineXL() => GoogleFonts.inter(
    fontSize: 83,
    fontWeight: FontWeight.w700,
    color: GlassColors.onSurface,
    letterSpacing: -0.02 * 83,
    height: 1.1,
  );

  static TextStyle headlineLG() => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w600,
    color: GlassColors.onSurface,
    height: 1.15,
  );

  static TextStyle headlineMD() => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: GlassColors.onSurface,
    height: 1.25,
  );

  // Body & Labels (Inter)
  static TextStyle bodyLG() => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: GlassColors.onSurface,
    height: 1.5,
  );

  static TextStyle bodyMD() => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: GlassColors.onSurface,
    height: 1.55,
  );

  static TextStyle secondary() => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: GlassColors.onSurfaceVariant,
    height: 1.5,
  );

  static TextStyle labelSM() => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: GlassColors.onSurface,
    letterSpacing: 1.0,
    height: 1.4,
  );

  // Monospace (JetBrains Mono)
  static TextStyle mono([double size = 12]) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: GlassColors.onSurfaceVariant,
  );

  // Legacy alias for compatibility
  static TextStyle headline([bool isDark = true]) => headlineLG();
  static TextStyle title([bool isDark = true]) => headlineMD();
  static TextStyle body([bool isDark = true]) => bodyMD();
  static TextStyle label([bool isDark = true]) =>
      labelSM().copyWith(color: GlassColors.primary);
  static TextStyle caption([bool isDark = true]) =>
      secondary().copyWith(fontSize: 12);
}

class GlassAppTheme {
  static ThemeData dark() {
    final base = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: GlassColors.background,
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    return base.copyWith(
      canvasColor: GlassColors.background,
      cardColor: GlassColors.surface,
      dividerColor: GlassColors.hairline,
      iconTheme: const IconThemeData(
        color: GlassColors.onSurfaceVariant,
        size: 18,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: GlassColors.onSurface,
        displayColor: GlassColors.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GlassColors.gold.withOpacity(0.1),
          foregroundColor: GlassColors.gold,
          side: BorderSide(
            color: GlassColors.gold.withOpacity(0.3),
            width: 1.0,
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: GlassText.bodyMD().copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GlassColors.onSurfaceVariant,
          side: BorderSide(color: GlassColors.hairlineStrong.withOpacity(0.9)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GlassColors.onSurfaceVariant,
          textStyle: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ExecutiveRadius.l),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.015),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GlassText.bodyMD().copyWith(
          color: GlassColors.onSurfaceVariant.withOpacity(0.34),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
          borderSide: BorderSide(
            color: GlassColors.hairlineStrong.withOpacity(0.8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
          borderSide: BorderSide(color: GlassColors.primary.withOpacity(0.22)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
          borderSide: BorderSide(
            color: GlassColors.hairlineStrong.withOpacity(0.8),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: GlassColors.hairlineStrong.withOpacity(0.42),
        thickness: 1,
        space: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.transparent,
        selectedColor: GlassColors.primary.withOpacity(0.08),
        side: BorderSide(color: GlassColors.hairlineStrong.withOpacity(0.72)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: GlassText.secondary().copyWith(fontSize: 13),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: const WidgetStatePropertyAll(false),
        radius: const Radius.circular(999),
        thickness: const WidgetStatePropertyAll(8),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) {
            return GlassColors.onSurfaceVariant.withOpacity(0.55);
          }
          return GlassColors.onSurfaceVariant.withOpacity(0.28);
        }),
      ),
    );
  }
}
