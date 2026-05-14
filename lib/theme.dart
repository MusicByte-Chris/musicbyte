import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// User-selectable global app color schemas.
///
/// Stored as string ids in [AppSettings.appColorScheme].
enum AppColorSchemeId {
  luxury,
  ocean,
  forest,
  rose,
  mono,
}

AppColorSchemeId appColorSchemeIdFromString(String? raw) {
  final v = (raw ?? '').trim().toLowerCase();
  for (final id in AppColorSchemeId.values) {
    if (id.name == v) return id;
  }
  return AppColorSchemeId.luxury;
}

String appColorSchemeLabel(AppColorSchemeId id) => switch (id) {
      AppColorSchemeId.luxury => 'Luxury Gold',
      AppColorSchemeId.ocean => 'Ocean Blue',
      AppColorSchemeId.forest => 'Forest Green',
      AppColorSchemeId.rose => 'Rose Ember',
      AppColorSchemeId.mono => 'Monochrome',
    };

class AppColorSchemeSpec {
  final AppColorSchemeId id;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color error;
  final Color darkBackground;
  final Color darkSurface;
  final Color darkCard;
  final Color darkOnSurface;
  final Color darkSecondaryText;
  final Color darkOutline;
  final Color lightBackground;
  final Color lightSurface;
  final Color lightCard;
  final Color lightOnSurface;
  final Color lightSecondaryText;
  final Color lightOutline;

  const AppColorSchemeSpec({
    required this.id,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.error,
    required this.darkBackground,
    required this.darkSurface,
    required this.darkCard,
    required this.darkOnSurface,
    required this.darkSecondaryText,
    required this.darkOutline,
    required this.lightBackground,
    required this.lightSurface,
    required this.lightCard,
    required this.lightOnSurface,
    required this.lightSecondaryText,
    required this.lightOutline,
  });
}

/// Central catalog of supported schemas.
///
/// Keep all color constants here (never scattered in widgets).
class AppColorSchemes {
  static const luxury = AppColorSchemeSpec(
    id: AppColorSchemeId.luxury,
    primary: AppColors.gold,
    secondary: AppColors.amberWarm,
    tertiary: AppColors.ember,
    error: AppColors.destructive,
    darkBackground: AppColors.background,
    darkSurface: AppColors.charcoal,
    darkCard: AppColors.card,
    darkOnSurface: AppColors.foreground,
    darkSecondaryText: AppColors.mutedForeground,
    darkOutline: AppColors.border,
    lightBackground: AppLiteColors.background,
    lightSurface: AppLiteColors.surface,
    lightCard: AppLiteColors.card,
    lightOnSurface: AppLiteColors.foreground,
    lightSecondaryText: AppLiteColors.secondaryText,
    lightOutline: AppLiteColors.border,
  );

  static const ocean = AppColorSchemeSpec(
    id: AppColorSchemeId.ocean,
    primary: Color(0xFF3BA7FF),
    secondary: Color(0xFF2DD4BF),
    tertiary: Color(0xFF8B5CF6),
    error: Color(0xFFEF4444),
    darkBackground: Color(0xFF0B1220),
    darkSurface: Color(0xFF101C2E),
    darkCard: Color(0xFF13243A),
    darkOnSurface: Color(0xFFEAF2FF),
    darkSecondaryText: Color(0xFF9CB3D3),
    darkOutline: Color(0xFF2A3D59),
    lightBackground: Color(0xFFF6FBFF),
    lightSurface: Color(0xFFFFFFFF),
    lightCard: Color(0xFFF2F8FF),
    lightOnSurface: Color(0xFF0C1A2B),
    lightSecondaryText: Color(0xFF415A78),
    lightOutline: Color(0xFFCFDFF0),
  );

  static const forest = AppColorSchemeSpec(
    id: AppColorSchemeId.forest,
    primary: Color(0xFF34D399),
    secondary: Color(0xFFA3E635),
    tertiary: Color(0xFF22C55E),
    error: Color(0xFFEF4444),
    darkBackground: Color(0xFF0D1411),
    darkSurface: Color(0xFF121D18),
    darkCard: Color(0xFF16261F),
    darkOnSurface: Color(0xFFEAF7EF),
    darkSecondaryText: Color(0xFF9CB8A8),
    darkOutline: Color(0xFF2A3B33),
    lightBackground: Color(0xFFF6FBF7),
    lightSurface: Color(0xFFFFFFFF),
    lightCard: Color(0xFFF0F9F2),
    lightOnSurface: Color(0xFF0E1B14),
    lightSecondaryText: Color(0xFF466354),
    lightOutline: Color(0xFFCFDDD5),
  );

  static const rose = AppColorSchemeSpec(
    id: AppColorSchemeId.rose,
    primary: Color(0xFFFB7185),
    secondary: Color(0xFFF59E0B),
    tertiary: Color(0xFFEC4899),
    error: Color(0xFFEF4444),
    darkBackground: Color(0xFF160C12),
    darkSurface: Color(0xFF21101A),
    darkCard: Color(0xFF2A1421),
    darkOnSurface: Color(0xFFFFF1F6),
    darkSecondaryText: Color(0xFFC9A6B3),
    darkOutline: Color(0xFF4A2333),
    lightBackground: Color(0xFFFFF7FA),
    lightSurface: Color(0xFFFFFFFF),
    lightCard: Color(0xFFFFF1F6),
    lightOnSurface: Color(0xFF231018),
    lightSecondaryText: Color(0xFF6F3A4E),
    lightOutline: Color(0xFFF0C9D6),
  );

  static const mono = AppColorSchemeSpec(
    id: AppColorSchemeId.mono,
    primary: Color(0xFFE5E7EB),
    secondary: Color(0xFF9CA3AF),
    tertiary: Color(0xFFFFFFFF),
    error: Color(0xFFEF4444),
    darkBackground: Color(0xFF0B0D10),
    darkSurface: Color(0xFF11151B),
    darkCard: Color(0xFF141A21),
    darkOnSurface: Color(0xFFF3F4F6),
    darkSecondaryText: Color(0xFF9CA3AF),
    darkOutline: Color(0xFF2A3340),
    lightBackground: Color(0xFFFAFAFA),
    lightSurface: Color(0xFFFFFFFF),
    lightCard: Color(0xFFF6F7F9),
    lightOnSurface: Color(0xFF0B0D10),
    lightSecondaryText: Color(0xFF4B5563),
    lightOutline: Color(0xFFE5E7EB),
  );

  static const all = <AppColorSchemeSpec>[luxury, ocean, forest, rose, mono];

  static AppColorSchemeSpec byId(AppColorSchemeId id) => all.firstWhere((e) => e.id == id, orElse: () => luxury);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);
}

/// Convenience getters to avoid nullable theme fields causing runtime crashes
/// (notably `ThemeData.cardTheme.color`, which is nullable in newer Flutter).
extension ThemeDataSafeColors on ThemeData {
  Color get safeCardColor => cardTheme.color ?? colorScheme.surface;
  Color get safeSurfaceColor => colorScheme.surface;
  Color get safeScaffoldColor => scaffoldBackgroundColor;
}

class AppRadius {
  // Matches design tokens (rem -> dp assuming 16px base):
  // sm: 0.25rem (4), md: 0.375rem (6), lg/base: 0.5rem (8), xl: 0.75rem (12)
  static const double sm = 4.0;
  static const double md = 6.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
  static const double full = 9999.0;
}

class AppColors {
  // Cinematic dark luxury palette (user-provided tokens).
  static const background = Color(0xFF1F1A14);
  static const foreground = Color(0xFFF5F0E6);
  static const onyx = Color(0xFF161310);
  static const charcoal = Color(0xFF2A241D);
  static const card = Color(0xFF27221B);
  static const gold = Color(0xFFD4B059);
  static const goldSoft = Color(0xFFA88B4A);
  static const amberWarm = Color(0xFFD68A3C);
  static const ember = Color(0xFFC2461F);
  static const muted = Color(0xFF2F2820);
  static const mutedForeground = Color(0xFFA39581);
  static const border = Color(0xFF473D30);
  static const destructive = Color(0xFFC43A1F);

  // Selection: gold bg + onyx text.
  static const selectionBackground = gold;
  static const selectionForeground = onyx;

  // Splash
  static const splashBackgroundDark = onyx;
  static const splashBackgroundLight = onyx;
  static const splashForeground = foreground;
  static const splashForegroundMuted = mutedForeground;
  static const splashForegroundError = destructive;

  // EQ Spectrum warm gradient endpoints
  static const eqLow = goldSoft;
  static const eqHigh = amberWarm;

  // Interval Colors (used by chord/scale visualizer)
  // IMPORTANT: These are intentionally NOT derived from the app's gold/onyx palette.
  // They follow common music-theory visual conventions (high-chroma, categorical hues)
  // so scale/chord tones are instantly distinguishable on instruments.
  //
  // Legend (app-wide):
  // - Root: Teal
  // - 3rd: Light Blue
  // - 5th: Neutral Gray
  // - 7th: Purple
  // - Other tones / extensions: Orange
  static const intervalRoot = Color(0xFF2DD4BF); // teal
  static const intervalThird = Color(0xFF60A5FA); // light blue
  static const intervalFifth = Color(0xFFA1A1AA); // neutral gray
  static const intervalSeventh = Color(0xFFA78BFA); // purple
  static const intervalExtension = Color(0xFFFB923C); // orange

  // Printed chord-chart palette (paper + ink)
  // Keep these neutral so printed exports remain readable.
  static const chordPaperLight = Color(0xFFFFFFFF);
  static const chordPaperDark = Color(0xFFF4F6F7);
  static const chordInk = Color(0xFF141718);
  static const chordPaperBorderLight = Color(0xFFE3E7EA);
  static const chordPaperBorderDark = Color(0xFFD5DADD);
}

/// Complementary "Lite" palette.
///
/// This is a warm parchment / studio-daylight look that still keeps the brand's
/// gold accent and avoids harsh pure-white UIs.
class AppLiteColors {
  static const background = Color(0xFFFBF7EF); // warm parchment
  static const surface = Color(0xFFFFFFFF);
  static const card = Color(0xFFFFF9F0);
  static const foreground = Color(0xFF191614); // deep espresso
  static const secondaryText = Color(0xFF5E554A);
  static const border = Color(0xFFE4D8C7);
  static const muted = Color(0xFFF4EBDD);
  static const onPrimary = Color(0xFF191614);
}

@immutable
class ChordChartColors extends ThemeExtension<ChordChartColors> {
  final Color paper;
  final Color ink;
  final Color border;

  const ChordChartColors({required this.paper, required this.ink, required this.border});

  factory ChordChartColors.light() => const ChordChartColors(
        paper: AppColors.chordPaperLight,
        ink: AppColors.chordInk,
        border: AppColors.chordPaperBorderLight,
      );

  factory ChordChartColors.dark() => const ChordChartColors(
        paper: AppColors.chordPaperDark,
        ink: AppColors.chordInk,
        border: AppColors.chordPaperBorderDark,
      );

  @override
  ThemeExtension<ChordChartColors> copyWith({Color? paper, Color? ink, Color? border}) =>
      ChordChartColors(paper: paper ?? this.paper, ink: ink ?? this.ink, border: border ?? this.border);

  @override
  ThemeExtension<ChordChartColors> lerp(ThemeExtension<ChordChartColors>? other, double t) {
    if (other is! ChordChartColors) return this;
    return ChordChartColors(
      paper: Color.lerp(paper, other.paper, t) ?? paper,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      border: Color.lerp(border, other.border, t) ?? border,
    );
  }
}

@immutable
class IntervalColors extends ThemeExtension<IntervalColors> {
  final Color root;
  final Color third;
  final Color fifth;
  final Color seventh;
  final Color extensionColor;

  const IntervalColors({
    required this.root,
    required this.third,
    required this.fifth,
    required this.seventh,
    required this.extensionColor,
  });

  factory IntervalColors.light() => const IntervalColors(
        root: AppColors.intervalRoot,
        third: AppColors.intervalThird,
        fifth: AppColors.intervalFifth,
        seventh: AppColors.intervalSeventh,
        extensionColor: AppColors.intervalExtension,
      );

  factory IntervalColors.dark() => const IntervalColors(
        root: AppColors.intervalRoot,
        third: AppColors.intervalThird,
        fifth: AppColors.intervalFifth,
        seventh: AppColors.intervalSeventh,
        extensionColor: AppColors.intervalExtension,
      );

  @override
  ThemeExtension<IntervalColors> copyWith({
    Color? root,
    Color? third,
    Color? fifth,
    Color? seventh,
    Color? extensionColor,
  }) => IntervalColors(
        root: root ?? this.root,
        third: third ?? this.third,
        fifth: fifth ?? this.fifth,
        seventh: seventh ?? this.seventh,
        extensionColor: extensionColor ?? this.extensionColor,
      );

  @override
  ThemeExtension<IntervalColors> lerp(ThemeExtension<IntervalColors>? other, double t) {
    if (other is! IntervalColors) return this;
    return IntervalColors(
      root: Color.lerp(root, other.root, t) ?? root,
      third: Color.lerp(third, other.third, t) ?? third,
      fifth: Color.lerp(fifth, other.fifth, t) ?? fifth,
      seventh: Color.lerp(seventh, other.seventh, t) ?? seventh,
      extensionColor: Color.lerp(extensionColor, other.extensionColor, t) ?? extensionColor,
    );
  }
}

TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
  const displayTighten = -0.02;
  return TextTheme(
    headlineLarge: GoogleFonts.cormorantGaramond(
      fontSize: 40,
      fontWeight: FontWeight.w500,
      height: 1.08,
      letterSpacing: displayTighten * 40,
      color: primaryColor,
    ),
    headlineMedium: GoogleFonts.cormorantGaramond(
      fontSize: 32,
      fontWeight: FontWeight.w500,
      height: 1.1,
      letterSpacing: displayTighten * 32,
      color: primaryColor,
    ),
    headlineSmall: GoogleFonts.cormorantGaramond(
      fontSize: 26,
      fontWeight: FontWeight.w500,
      height: 1.15,
      letterSpacing: displayTighten * 26,
      color: primaryColor,
    ),
    titleLarge: GoogleFonts.cormorantGaramond(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: displayTighten * 22,
      color: primaryColor,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.35,
      letterSpacing: -0.2,
      color: primaryColor,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.35,
      letterSpacing: -0.1,
      color: primaryColor,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
      color: secondaryColor,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: secondaryColor,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: secondaryColor,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.1,
      letterSpacing: 0.2,
      color: primaryColor,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.1,
      letterSpacing: 2.2,
      color: primaryColor,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      height: 1.1,
      letterSpacing: 2.0,
      color: primaryColor,
    ),
  );
}

Color _onColorFor(Color bg) => bg.computeLuminance() > 0.55 ? const Color(0xFF0B0D10) : Colors.white;

ThemeData buildAppTheme({required Brightness brightness, required AppColorSchemeId schemeId}) {
  final isDark = brightness == Brightness.dark;

  final spec = AppColorSchemes.byId(schemeId);

  final bg = isDark ? spec.darkBackground : spec.lightBackground;
  final surface = isDark ? spec.darkSurface : spec.lightSurface;
  final card = isDark ? spec.darkCard : spec.lightCard;
  final onSurface = isDark ? spec.darkOnSurface : spec.lightOnSurface;
  final secondaryText = isDark ? spec.darkSecondaryText : spec.lightSecondaryText;
  final outline = isDark ? spec.darkOutline : spec.lightOutline;

  final primary = spec.primary;
  final onPrimary = _onColorFor(primary);
  final secondary = spec.secondary;
  final onSecondary = _onColorFor(secondary);
  final tertiary = spec.tertiary;
  final onTertiary = _onColorFor(tertiary);

  final primary20 = primary.withValues(alpha: isDark ? 0.20 : 0.16);
  final primary35 = primary.withValues(alpha: isDark ? 0.35 : 0.26);

  final colorScheme = (isDark
          ? ColorScheme.dark(
              primary: primary,
              onPrimary: onPrimary,
              secondary: secondary,
              onSecondary: onSecondary,
              tertiary: tertiary,
              onTertiary: onTertiary,
              error: spec.error,
              onError: _onColorFor(spec.error),
              surface: surface,
              onSurface: onSurface,
              outline: outline,
            )
          : ColorScheme.light(
              primary: primary,
              onPrimary: onPrimary,
              secondary: secondary,
              onSecondary: onSecondary,
              tertiary: tertiary,
              onTertiary: onTertiary,
              error: spec.error,
              onError: _onColorFor(spec.error),
              surface: surface,
              onSurface: onSurface,
              outline: outline,
            ))
      .copyWith(brightness: brightness);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: primary.withValues(alpha: 0.04),
    focusColor: primary.withValues(alpha: 0.08),
    dividerColor: outline,
    dividerTheme: DividerThemeData(color: outline.withValues(alpha: isDark ? 0.45 : 0.8), thickness: 1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: primary,
      selectionColor: primary.withValues(alpha: isDark ? 0.28 : 0.22),
      selectionHandleColor: primary,
    ),
    iconTheme: IconThemeData(color: onSurface),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? spec.darkSurface : bg,
      foregroundColor: onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: _buildTextTheme(onSurface, secondaryText).titleLarge,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: outline)),
      iconTheme: IconThemeData(color: onSurface),
      actionsIconTheme: IconThemeData(color: primary),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: primary20, width: 1),
      ),
      margin: const EdgeInsets.all(0),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: primary20, width: 1),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? spec.darkSurface : spec.lightSurface,
      contentTextStyle: _buildTextTheme(onSurface, secondaryText).bodyMedium,
      actionTextColor: primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl), side: BorderSide(color: primary20, width: 1)),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? spec.darkSurface.withValues(alpha: 0.75) : spec.lightCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xl), borderSide: BorderSide(color: primary20, width: 1)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xl), borderSide: BorderSide(color: primary20, width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xl), borderSide: BorderSide(color: primary35, width: 1.2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xl), borderSide: BorderSide(color: spec.error.withValues(alpha: 0.7), width: 1.2)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.xl), borderSide: BorderSide(color: spec.error, width: 1.4)),
      labelStyle: _buildTextTheme(onSurface, secondaryText).bodySmall?.copyWith(color: secondaryText),
      hintStyle: _buildTextTheme(onSurface, secondaryText).bodySmall?.copyWith(color: secondaryText.withValues(alpha: 0.8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(primary),
        foregroundColor: WidgetStatePropertyAll(onPrimary),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
        overlayColor: WidgetStatePropertyAll(onPrimary.withValues(alpha: 0.08)),
        textStyle: WidgetStatePropertyAll(_buildTextTheme(onPrimary, onPrimary).labelLarge),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(primary),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
        side: WidgetStatePropertyAll(BorderSide(color: primary35, width: 1)),
        overlayColor: WidgetStatePropertyAll(primary.withValues(alpha: 0.07)),
        textStyle: WidgetStatePropertyAll(_buildTextTheme(primary, primary).labelLarge),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(primary),
        overlayColor: WidgetStatePropertyAll(primary.withValues(alpha: 0.07)),
        textStyle: WidgetStatePropertyAll(_buildTextTheme(primary, primary).labelLarge),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? spec.darkSurface : bg,
      indicatorColor: primary.withValues(alpha: 0.18),
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(_buildTextTheme(onSurface, secondaryText).labelSmall?.copyWith(color: secondaryText)),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(color: isSelected ? primary : secondaryText, size: 22);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: isDark ? spec.darkSurface : bg,
      indicatorColor: primary.withValues(alpha: 0.14),
      selectedIconTheme: IconThemeData(color: primary),
      unselectedIconTheme: IconThemeData(color: secondaryText),
      selectedLabelTextStyle: _buildTextTheme(onSurface, secondaryText).labelMedium?.copyWith(color: primary),
      unselectedLabelTextStyle: _buildTextTheme(onSurface, secondaryText).labelMedium?.copyWith(color: secondaryText),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: secondaryText,
      textColor: onSurface,
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? spec.darkSurface.withValues(alpha: 0.7) : spec.lightCard,
      side: BorderSide(color: primary20, width: 1),
      selectedColor: primary.withValues(alpha: 0.14),
      disabledColor: (isDark ? spec.darkSurface : spec.lightCard).withValues(alpha: 0.6),
      labelStyle: _buildTextTheme(onSurface, secondaryText).bodySmall,
      secondaryLabelStyle: _buildTextTheme(onSurface, secondaryText).bodySmall,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
    ),
    textTheme: _buildTextTheme(onSurface, secondaryText),
    extensions: <ThemeExtension<dynamic>>[
      isDark ? IntervalColors.dark() : IntervalColors.light(),
      isDark ? EqColors.dark() : EqColors.light(),
      isDark ? ChordChartColors.dark() : ChordChartColors.light(),
      LuxuryTokens.fromScheme(colorScheme: colorScheme, isDark: isDark),
    ],
  );
}

ThemeData appLightTheme(AppColorSchemeId schemeId) => buildAppTheme(brightness: Brightness.light, schemeId: schemeId);
ThemeData appDarkTheme(AppColorSchemeId schemeId) => buildAppTheme(brightness: Brightness.dark, schemeId: schemeId);

// Back-compat: default themes.
ThemeData get lightTheme => appLightTheme(AppColorSchemeId.luxury);
ThemeData get darkTheme => appDarkTheme(AppColorSchemeId.luxury);

/// Extra brand tokens not representable via core ThemeData.
@immutable
class LuxuryTokens extends ThemeExtension<LuxuryTokens> {
  final LinearGradient primaryGradient;
  final LinearGradient secondaryGradient;
  final RadialGradient ambientGlow;

  const LuxuryTokens({required this.primaryGradient, required this.secondaryGradient, required this.ambientGlow});

  factory LuxuryTokens.fromScheme({required ColorScheme colorScheme, required bool isDark}) {
    final a = colorScheme.primary;
    final b = colorScheme.secondary;
    final c = colorScheme.tertiary;
    return LuxuryTokens(
      primaryGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]),
      secondaryGradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [b, c]),
      ambientGlow: RadialGradient(
        radius: 0.9,
        colors: [b.withValues(alpha: isDark ? 0.16 : 0.10), Colors.transparent],
        stops: const [0, 0.7],
      ),
    );
  }

  @override
  LuxuryTokens copyWith({LinearGradient? primaryGradient, LinearGradient? secondaryGradient, RadialGradient? ambientGlow}) => LuxuryTokens(
        primaryGradient: primaryGradient ?? this.primaryGradient,
        secondaryGradient: secondaryGradient ?? this.secondaryGradient,
        ambientGlow: ambientGlow ?? this.ambientGlow,
      );

  @override
  ThemeExtension<LuxuryTokens> lerp(covariant ThemeExtension<LuxuryTokens>? other, double t) {
    if (other is! LuxuryTokens) return this;
    return LuxuryTokens(
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t) ?? primaryGradient,
      secondaryGradient: LinearGradient.lerp(secondaryGradient, other.secondaryGradient, t) ?? secondaryGradient,
      ambientGlow: RadialGradient.lerp(ambientGlow, other.ambientGlow, t) ?? ambientGlow,
    );
  }
}

/// Full-app ambient background (radial glows + subtle grain).
///
/// Use this behind every route via `MaterialApp.builder`.
class AppAmbientBackground extends StatelessWidget {
  final Widget child;
  const AppAmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<LuxuryTokens>() ?? LuxuryTokens.fromScheme(colorScheme: Theme.of(context).colorScheme, isDark: Theme.of(context).brightness == Brightness.dark);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentA = Theme.of(context).colorScheme.secondary;
    final accentB = Theme.of(context).colorScheme.tertiary;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            gradient: RadialGradient(
              center: const Alignment(0.0, -1.15),
              radius: 1.15,
              colors: [accentA.withValues(alpha: isDark ? 0.20 : 0.10), Colors.transparent],
              stops: const [0, 0.6],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1.05, 1.05),
              radius: 1.1,
              colors: [accentB.withValues(alpha: isDark ? 0.14 : 0.08), Colors.transparent],
              stops: const [0, 0.6],
            ),
          ),
        ),
        if (isDark) DecoratedBox(decoration: BoxDecoration(gradient: tokens.ambientGlow)),
        const _GrainOverlay(),
        child,
      ],
    );
  }
}

class _GrainOverlay extends StatelessWidget {
  const _GrainOverlay();

  @override
  Widget build(BuildContext context) {
    // Keep it very subtle; also wrap in IgnorePointer so it never interferes.
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _GrainPainter(density: 0.085),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  final double density;
  final List<Offset> _points;
  final List<double> _alphas;

  _GrainPainter({required this.density})
      : _points = List<Offset>.generate(1200, (i) {
          final r = math.Random(i * 9973);
          return Offset(r.nextDouble(), r.nextDouble());
        }),
        _alphas = List<double>.generate(1200, (i) {
          final r = math.Random(i * 733);
          return r.nextDouble();
        });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: density);
    final paintDark = Paint()..color = Colors.black.withValues(alpha: density * 0.9);
    final s = math.min(size.width, size.height);
    if (s <= 0) return;

    for (var i = 0; i < _points.length; i++) {
      final p = _points[i];
      final dx = p.dx * size.width;
      final dy = p.dy * size.height;
      final a = _alphas[i];
      final useDark = a > 0.55;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1, 1), useDark ? paintDark : paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) => false;
}

@immutable
class EqColors extends ThemeExtension<EqColors> {
  final Color low;
  final Color high;

  const EqColors({required this.low, required this.high});

  factory EqColors.light() => const EqColors(low: AppColors.eqLow, high: AppColors.eqHigh);
  factory EqColors.dark() => const EqColors(low: AppColors.eqLow, high: AppColors.eqHigh);

  @override
  ThemeExtension<EqColors> copyWith({Color? low, Color? high}) => EqColors(low: low ?? this.low, high: high ?? this.high);

  @override
  ThemeExtension<EqColors> lerp(ThemeExtension<EqColors>? other, double t) {
    if (other is! EqColors) return this;
    return EqColors(
      low: Color.lerp(low, other.low, t) ?? low,
      high: Color.lerp(high, other.high, t) ?? high,
    );
  }
}
