import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aether AI Design System (Soft UI & Bento Box Pastel Mobile-First Theme)

class GlassColors {
  // Soft UI & Bento Pastel Palette
  static const Color background = Color(0xFFF8F9FA); // Off-white soft background
  static const Color surface = Color(0xFFFFFFFF); // Clean white card surface
  static const Color surfaceBright = Color(0xFFF4F5F8);
  static const Color surfaceContainer = Color(0xFFEFEFF4);
  static const Color surfaceHighest = Color(0xFFE4E4EC);

  static const Color deepBlack = Color(0xFF1E1E24); // Primary active & bottom nav
  static const Color primary = Color(0xFF1E1E24);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Bento Box Custom Vibrant Pastel Tokens
  static const Color bentoLavender = Color(0xFFB3A0FF); // Daily Challenge card (#B3A0FF)
  static const Color bentoOrange = Color(0xFFFFBE5A);   // Meeting card (#FFBE5A)
  static const Color bentoBlue = Color(0xFFA9CBFF);     // Message with AI card (#A9CBFF)
  static const Color bentoPink = Color(0xFFFD9FFF);     // Profile & Sync card (#FD9FFF)

  static const Color secondary = Color(0xFF6C5CE7);
  static const Color tertiary = Color(0xFFFF7675);
  static const Color gold = Color(0xFFFDCB6E);
  static const Color hairline = Color(0xFFE8E8EE);
  static const Color hairlineStrong = Color(0xFFDDDDE6);
  static const Color muted = Color(0xFF9595A6);

  static const Color onSurface = Color(0xFF1E1E24); // Deep dark text
  static const Color onSurfaceVariant = Color(0xFF6E6E7E); // Soft dark-grey text
  static const Color outline = Color(0xFFE0E0EA);
  static const Color outlineVariant = Color(0xFFECECF4);

  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFD63031);

  static Color glassSurface = Colors.white;
  static Color ghostBorder = const Color(0xFFE8E8EE);

  static Color glassBorder() => ghostBorder;
  static Color glassTint() => deepBlack.withOpacity(0.03);

  static const List<Color> memberPalette = [
    Color(0xFF00B894),
    Color(0xFFFDCB6E),
    Color(0xFF0984E3),
    Color(0xFFD63031),
    Color(0xFF6C5CE7),
    Color(0xFFE84393),
    Color(0xFFE17055),
    Color(0xFF00CEC9),
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

  static double stackMd(BuildContext context) =>
      MediaQuery.of(context).size.width < 600 ? 16.0 : 32.0;

  static double gutter(BuildContext context) =>
      MediaQuery.of(context).size.width < 600 ? 12.0 : 24.0;

  static double containerPadding(BuildContext context) =>
      MediaQuery.of(context).size.width < 600 ? 16.0 : 64.0;

  static double sectionGap(BuildContext context) =>
      MediaQuery.of(context).size.width < 600 ? 48.0 : 160.0;

  static double get m => 16.0;
  static double get l => 24.0;
}

class ExecutiveRadius {
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 24.0;  // Bento standard rounded corner
  static const double xxl = 32.0; // Large Bento card rounded corner
  static const double circular = 9999.0;
}

class GlassGradients {
  static LinearGradient background() => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [GlassColors.background, Color(0xFFF0F1F5)],
  );
}

class GlassDecorations {
  static BoxDecoration softCard({
    Color backgroundColor = GlassColors.surface,
    double radius = ExecutiveRadius.xl, // 24px default
    bool hasShadow = true,
  }) => BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
    boxShadow: hasShadow
        ? [
            BoxShadow(
              color: const Color(0xFF1E1E24).withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ]
        : [],
  );

  static BoxDecoration surface({
    bool isDark = false,
    double radius = ExecutiveRadius.xl,
    bool hasShadow = true,
  }) => softCard(backgroundColor: GlassColors.surface, radius: radius, hasShadow: hasShadow);

  static BoxDecoration solidSurface({
    double radius = ExecutiveRadius.xl,
    bool hasShadow = true,
  }) => softCard(backgroundColor: GlassColors.surface, radius: radius, hasShadow: hasShadow);

  static BoxDecoration elevated({bool isDark = false, double radius = ExecutiveRadius.xl}) =>
      softCard(backgroundColor: GlassColors.surface, radius: radius, hasShadow: true);

  static BoxDecoration button({bool isDark = false, bool isGold = false}) {
    return BoxDecoration(
      color: isGold ? GlassColors.gold.withOpacity(0.2) : GlassColors.deepBlack,
      borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
      boxShadow: [
        BoxShadow(
          color: GlassColors.deepBlack.withOpacity(0.12),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration ghostButton({bool isGold = false}) {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(ExecutiveRadius.circular),
      border: Border.all(
        color: GlassColors.outline.withOpacity(0.8),
        width: 1.0,
      ),
    );
  }
}

class GlassText {
  static TextStyle headlineXL() => GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: GlassColors.onSurface,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static TextStyle headlineLG() => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: GlassColors.onSurface,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static TextStyle headlineMD() => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: GlassColors.onSurface,
    height: 1.25,
  );

  static TextStyle bodyLG() => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: GlassColors.onSurface,
    height: 1.5,
  );

  static TextStyle bodyMD() => GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: GlassColors.onSurface,
    height: 1.5,
  );

  static TextStyle secondary() => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: GlassColors.onSurfaceVariant,
    height: 1.4,
  );

  static TextStyle labelSM() => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: GlassColors.onSurface,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static TextStyle mono([double size = 12]) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: FontWeight.w400,
    color: GlassColors.onSurfaceVariant,
  );

  static TextStyle headline([bool isDark = false]) => headlineLG();
  static TextStyle title([bool isDark = false]) => headlineMD();
  static TextStyle body([bool isDark = false]) => bodyMD();
  static TextStyle label([bool isDark = false]) => labelSM();
  static TextStyle caption([bool isDark = false]) => secondary();
}

class GlassAppTheme {
  static ThemeData dark() => light();

  static ThemeData light() {
    final base = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: GlassColors.background,
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
    );

    return base.copyWith(
      canvasColor: GlassColors.background,
      cardColor: GlassColors.surface,
      dividerColor: GlassColors.hairline,
      iconTheme: const IconThemeData(
        color: GlassColors.onSurface,
        size: 20,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: GlassColors.onSurface,
        displayColor: GlassColors.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GlassColors.deepBlack,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GlassText.bodyMD().copyWith(
            fontWeight: FontWeight.w600,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GlassColors.onSurface,
          side: BorderSide(color: GlassColors.hairlineStrong),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GlassColors.onSurface,
          textStyle: GlassText.bodyMD().copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ExecutiveRadius.m),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        hintStyle: GlassText.bodyMD().copyWith(
          color: GlassColors.onSurfaceVariant.withOpacity(0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
          borderSide: BorderSide(
            color: GlassColors.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
          borderSide: const BorderSide(color: GlassColors.deepBlack, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ExecutiveRadius.xl),
          borderSide: BorderSide(
            color: GlassColors.outlineVariant,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: GlassColors.hairline,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

