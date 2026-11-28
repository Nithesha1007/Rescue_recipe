import 'package:flutter/material.dart';

import '../domain/expiry_priority.dart';

// ---------------------------------------------------------------- Colors

abstract final class AppColors {
  // Brand palette
  static const Color forest = Color(0xFF0B3D2E);
  static const Color forestMid = Color(0xFF14573F);
  static const Color lime = Color(0xFF7BD389);
  static const Color limeSoft = Color(0xFFC8F5D0);
  static const Color orange = Color(0xFFFF8A3D);
  static const Color cream = Color(0xFFFFF8EC);
  static const Color darkSurface = Color(0xFF0E1512);

  // Neutrals
  static const Color ink = Color(0xFF1B1B1B);
  static const Color inkSoft = Color(0xFF4A5750);
  static const Color mist = Color(0xFFB9C4BD);

  // Priority colors (solid fills with matching on-colors, all >= 4.5:1)
  static const Color expired = Color(0xFF7B1111);
  static const Color onExpired = Color(0xFFFFFFFF);
  static const Color critical = Color(0xFFD32F2F);
  static const Color onCritical = Color(0xFFFFFFFF);
  static const Color high = orange;
  static const Color onHigh = Color(0xFF1B1B1B);
  static const Color medium = Color(0xFFFFC107);
  static const Color onMedium = Color(0xFF1B1B1B);
  static const Color low = Color(0xFF2E7D32);
  static const Color onLow = Color(0xFFFFFFFF);
  static const Color unknown = Color(0xFF616161);
  static const Color onUnknown = Color(0xFFFFFFFF);

  // Common neutral fills
  static const Color white = Color(0xFFFFFFFF);
  static const Color black45 = Color(0x73000000);

  // Confetti celebrations
  static const Color confettiOrange = Color(0xFFFF8A3D);
  static const Color confettiGreen = Color(0xFF7BD389);
  static const Color confettiYellow = Color(0xFFFFC107);
  static const Color confettiBlue = Color(0xFF29B6F6);
  static const Color confettiPurple = Color(0xFFAB47BC);
  static const Color confettiRed = Color(0xFFFF5252);

  // Score breakdown orange ramp
  static const Color breakdownOrangeDark = Color(0xFFD84315);
  static const Color breakdownOrangeMed = Color(0xFFFFB74D);
  static const Color breakdownOrangeLight = Color(0xFFFFCC80);

  // DishArt palette gradients
  static const Color dishArtAmber1 = Color(0xFFE65100);
  static const Color dishArtAmber2 = Color(0xFFF57C00);
  static const Color dishArtPink1 = Color(0xFFC2185B);
  static const Color dishArtPink2 = Color(0xFFE91E63);
  static const Color dishArtRed1 = Color(0xFFD32F2F);
  static const Color dishArtRed2 = Color(0xFFFF5252);
  static const Color dishArtGreen1 = Color(0xFF2E7D32);
  static const Color dishArtGreen2 = Color(0xFF4CAF50);
  static const Color dishArtWarm1 = Color(0xFFD84315);
  static const Color dishArtWarm2 = Color(0xFFFF8A3D);
}

// -------------------------------------------------------------- Scales

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

abstract final class AppSizes {
  static const double minTap = 48;
  static const double iconSm = 20;
  static const double icon = 24;
  static const double iconLg = 32;
  static const double ring = 56;
  static const double ringStroke = 6;
  static const double orb = 200;
  static const double dot = 8;
  static const double dotActive = 24;
  static const double divider = 1;
  static const double glassBlur = 16;
  static const double skeletonCard = 88;
  static const double emptyMaxWidth = 360;
  static const double maxContentWidth = 1100;
}

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 700);
}

abstract final class AppTypography {
  static const String headingFont = 'Fraunces';
  static const String bodyFont = 'Manrope';

  static TextTheme textTheme(Color color) {
    return const TextTheme(
      displaySmall: TextStyle(
        fontFamily: headingFont,
        fontSize: 32,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontFamily: headingFont,
        fontSize: 28,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        fontFamily: headingFont,
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontFamily: headingFont,
        fontSize: 22,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
    ).apply(bodyColor: color, displayColor: color);
  }

  static const TextStyle displayEmoji = TextStyle(fontSize: 54);
  static const TextStyle artEmoji = TextStyle(fontSize: 48);
  static const TextStyle badgeTiny = TextStyle(fontFamily: bodyFont, fontSize: 10, fontWeight: FontWeight.bold);
  static const TextStyle chipLabel = TextStyle(fontFamily: bodyFont, fontSize: 12);
}

// -------------------------------------------------------- ThemeExtension

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.glassFill,
    required this.glassBorder,
    required this.heroGlassFill,
    required this.heroGlassBorder,
    required this.heroStart,
    required this.heroEnd,
    required this.onHero,
    required this.onHeroMuted,
    required this.heroAction,
    required this.onHeroAction,
    required this.freshColor,
    required this.staleColor,
    required this.skeleton,
    required this.orbHighlight,
    required this.orbCore,
    required this.orbShade,
    required this.orbAccent,
    required this.orbGlow,
  });

  final Color glassFill;
  final Color glassBorder;
  final Color heroGlassFill;
  final Color heroGlassBorder;
  final Color heroStart;
  final Color heroEnd;
  final Color onHero;
  final Color onHeroMuted;
  final Color heroAction;
  final Color onHeroAction;
  final Color freshColor;
  final Color staleColor;
  final Color skeleton;
  final Color orbHighlight;
  final Color orbCore;
  final Color orbShade;
  final Color orbAccent;
  final Color orbGlow;

  static const AppTokens light = AppTokens(
    glassFill: Color(0xD9FFFFFF),
    glassBorder: Color(0x26FF8A3D),
    heroGlassFill: Color(0x1FFFFFFF),
    heroGlassBorder: Color(0x33FFFFFF),
    heroStart: AppColors.forest,
    heroEnd: AppColors.forestMid,
    onHero: AppColors.cream,
    onHeroMuted: Color(0xCCFFF8EC),
    heroAction: AppColors.orange,
    onHeroAction: Color(0xFF1B1B1B),
    freshColor: AppColors.low,
    staleColor: AppColors.critical,
    skeleton: Color(0xFFEADBCE),
    orbHighlight: Color(0xFFFFDCC2),
    orbCore: AppColors.orange,
    orbShade: Color(0xFFD66A23),
    orbAccent: AppColors.forest,
    orbGlow: AppColors.orange,
  );

  static const AppTokens dark = AppTokens(
    glassFill: Color(0x1AFFFFFF),
    glassBorder: Color(0x26FF8A3D),
    heroGlassFill: Color(0x1FFFFFFF),
    heroGlassBorder: Color(0x33FFFFFF),
    heroStart: Color(0xFF0B3D2E),
    heroEnd: AppColors.darkSurface,
    onHero: AppColors.cream,
    onHeroMuted: Color(0xCCFFF8EC),
    heroAction: AppColors.orange,
    onHeroAction: Color(0xFF1B1B1B),
    freshColor: AppColors.lime,
    staleColor: Color(0xFFFF6B6B),
    skeleton: Color(0xFF26201B),
    orbHighlight: Color(0xFFFFDCC2),
    orbCore: AppColors.orange,
    orbShade: Color(0xFFD66A23),
    orbAccent: AppColors.lime,
    orbGlow: AppColors.orange,
  );

  Color priorityColor(ExpiryPriority priority) => switch (priority) {
        ExpiryPriority.expired => AppColors.expired,
        ExpiryPriority.critical => AppColors.critical,
        ExpiryPriority.high => AppColors.high,
        ExpiryPriority.medium => AppColors.medium,
        ExpiryPriority.low => AppColors.low,
        ExpiryPriority.unknown => AppColors.unknown,
      };

  Color onPriorityColor(ExpiryPriority priority) => switch (priority) {
        ExpiryPriority.expired => AppColors.onExpired,
        ExpiryPriority.critical => AppColors.onCritical,
        ExpiryPriority.high => AppColors.onHigh,
        ExpiryPriority.medium => AppColors.onMedium,
        ExpiryPriority.low => AppColors.onLow,
        ExpiryPriority.unknown => AppColors.onUnknown,
      };

  @override
  AppTokens copyWith({
    Color? glassFill,
    Color? glassBorder,
    Color? heroGlassFill,
    Color? heroGlassBorder,
    Color? heroStart,
    Color? heroEnd,
    Color? onHero,
    Color? onHeroMuted,
    Color? heroAction,
    Color? onHeroAction,
    Color? freshColor,
    Color? staleColor,
    Color? skeleton,
    Color? orbHighlight,
    Color? orbCore,
    Color? orbShade,
    Color? orbAccent,
    Color? orbGlow,
  }) {
    return AppTokens(
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      heroGlassFill: heroGlassFill ?? this.heroGlassFill,
      heroGlassBorder: heroGlassBorder ?? this.heroGlassBorder,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      onHero: onHero ?? this.onHero,
      onHeroMuted: onHeroMuted ?? this.onHeroMuted,
      heroAction: heroAction ?? this.heroAction,
      onHeroAction: onHeroAction ?? this.onHeroAction,
      freshColor: freshColor ?? this.freshColor,
      staleColor: staleColor ?? this.staleColor,
      skeleton: skeleton ?? this.skeleton,
      orbHighlight: orbHighlight ?? this.orbHighlight,
      orbCore: orbCore ?? this.orbCore,
      orbShade: orbShade ?? this.orbShade,
      orbAccent: orbAccent ?? this.orbAccent,
      orbGlow: orbGlow ?? this.orbGlow,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      glassFill: l(glassFill, other.glassFill),
      glassBorder: l(glassBorder, other.glassBorder),
      heroGlassFill: l(heroGlassFill, other.heroGlassFill),
      heroGlassBorder: l(heroGlassBorder, other.heroGlassBorder),
      heroStart: l(heroStart, other.heroStart),
      heroEnd: l(heroEnd, other.heroEnd),
      onHero: l(onHero, other.onHero),
      onHeroMuted: l(onHeroMuted, other.onHeroMuted),
      heroAction: l(heroAction, other.heroAction),
      onHeroAction: l(onHeroAction, other.onHeroAction),
      freshColor: l(freshColor, other.freshColor),
      staleColor: l(staleColor, other.staleColor),
      skeleton: l(skeleton, other.skeleton),
      orbHighlight: l(orbHighlight, other.orbHighlight),
      orbCore: l(orbCore, other.orbCore),
      orbShade: l(orbShade, other.orbShade),
      orbAccent: l(orbAccent, other.orbAccent),
      orbGlow: l(orbGlow, other.orbGlow),
    );
  }
}

// ----------------------------------------------------------------- Theme

abstract final class AppTheme {
  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.orange,
    onPrimary: Color(0xFF1B1B1B),
    primaryContainer: Color(0xFFFFDCC2),
    onPrimaryContainer: Color(0xFF3A1A00),
    secondary: AppColors.forest,
    onSecondary: AppColors.cream,
    secondaryContainer: Color(0xFFEBE5D8),
    onSecondaryContainer: AppColors.forest,
    tertiary: AppColors.lime,
    onTertiary: Color(0xFF0B3D2E),
    tertiaryContainer: AppColors.limeSoft,
    onTertiaryContainer: Color(0xFF0B3D2E),
    error: AppColors.critical,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: AppColors.cream,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkSoft,
    outline: Color(0xFFB0A294),
    outlineVariant: Color(0xFFE3D7C8),
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFFBF3E4),
    surfaceContainerHigh: Color(0xFFF5ECDC),
    surfaceContainerHighest: Color(0xFFEFE4D2),
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.orange,
    onPrimary: Color(0xFF1B1B1B),
    primaryContainer: Color(0xFF5A2D0E),
    onPrimaryContainer: Color(0xFFFFDCC2),
    secondary: Color(0xFF86B8A0),
    onSecondary: Color(0xFF0B3D2E),
    secondaryContainer: Color(0xFF26332C),
    onSecondaryContainer: AppColors.cream,
    tertiary: AppColors.lime,
    onTertiary: Color(0xFF0B3D2E),
    tertiaryContainer: Color(0xFF1E3A28),
    onTertiaryContainer: AppColors.limeSoft,
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF3B0000),
    errorContainer: Color(0xFF5C1A1A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.darkSurface,
    onSurface: AppColors.cream,
    onSurfaceVariant: AppColors.mist,
    outline: Color(0xFF706B65),
    outlineVariant: Color(0xFF322C28),
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: Color(0xFF080D0B),
    surfaceContainerLow: Color(0xFF121B17),
    surfaceContainer: Color(0xFF18221D),
    surfaceContainerHigh: Color(0xFF1E2B25),
    surfaceContainerHighest: Color(0xFF26352E),
  );

  static ThemeData light() => _build(_lightScheme, AppTokens.light);

  static ThemeData dark() => _build(_darkScheme, AppTokens.dark);

  static ThemeData _build(ColorScheme scheme, AppTokens tokens) {
    final TextTheme text = AppTypography.textTheme(scheme.onSurface);
    const Size minButton = Size(AppSizes.minTap, AppSizes.minTap);
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.brightness == Brightness.dark ? scheme.onSurface : scheme.secondary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          color: scheme.brightness == Brightness.dark ? scheme.onSurface : scheme.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: AppSizes.divider,
        space: AppSizes.divider,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: minButton,
          padding: buttonPadding,
          shape: const StadiumBorder(),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: minButton,
          padding: buttonPadding,
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: minButton,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return text.labelSmall!.copyWith(
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color:
                selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle:
            text.labelMedium!.copyWith(color: scheme.onSurface),
        unselectedLabelTextStyle:
            text.labelMedium!.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

// ------------------------------------------------------ Context helpers

extension AppThemeContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
