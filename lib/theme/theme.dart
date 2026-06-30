import "package:flutter/material.dart";


abstract final class JalaBrand {
  static const Color amber = Color(0xffff8f00);
  static const Color amberDeep = Color(0xff9a5200);
  static const Color amberLight = Color(0xffffb066);
  static const Color ink = Color(0xff231d17);
  static const Color cream = Color(0xfffbf7f2);

  // Colores semánticos del proyecto (no están en ColorScheme estándar)
  static const Color greyDark = Color(0xff6B6661);
  static const Color greyLight = Color(0xffB6B3B1);
  static const Color greyBorder = Color(0xffD1D1D1);
  static const Color surfaceLight = Color(0xffF6F6F6);
  static const Color divider = Color(0xffECECEC);
  static const Color accentSurface = Color(0xffFFF1E0);
  static const Color accentBlue = Color(0xff005B9F);
  static const Color success = Color(0xff1E8E5A);
  static const Color successLight = Color(0xffE6F4EA);
  static const Color destructive = Color(0xffD84315);
  static const Color destructiveLight = Color(0xffFCEAE6);

  // Equivalentes para modo oscuro
  static const Color greyDarkDark = Color(0xffA8A29A);
  static const Color greyLightDark = Color(0xff7A746E);
  static const Color greyBorderDark = Color(0xff4A4540);
  static const Color surfaceLightDark = Color(0xff242017);
  static const Color dividerDark = Color(0xff3A352E);
  static const Color accentSurfaceDark = Color(0xff3A2E1A);
  static const Color accentBlueDark = Color(0xff4A9FE2);
  static const Color successDark = Color(0xff4EC080);
  static const Color successLightDark = Color(0xff1E3A2A);
  static const Color destructiveDark = Color(0xffFF6B4A);
  static const Color destructiveLightDark = Color(0xff3A1E18);

  // Helper para obtener colores semánticos según brightness
  static Color semantic(
    Brightness brightness, {
    required Color light,
    required Color dark,
  }) {
    return brightness == Brightness.dark ? dark : light;
  }
}

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: JalaBrand.ink,
      surfaceTint: JalaBrand.ink,
      onPrimary: Color(0xfffdf8f3),
      primaryContainer: Color(0xffefe6dc),
      onPrimaryContainer: Color(0xff231d17),
      secondary: JalaBrand.amberDeep,
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffffe1bb),
      onSecondaryContainer: Color(0xff5a3300),
      tertiary: Color(0xff765848),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffdcc2),
      onTertiaryContainer: Color(0xff2b1700),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: JalaBrand.cream,
      onSurface: Color(0xff221d18),
      onSurfaceVariant: Color(0xff51463b),
      outline: Color(0xff847568),
      outlineVariant: Color(0xffd6c6b6),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff372f27),
      onInverseSurface: Color(0xfffaeee2),
      inversePrimary: JalaBrand.amberLight,
      surfaceDim: Color(0xffe3dcd2),
      surfaceBright: Color(0xfffbf7f2),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff6f0e8),
      surfaceContainer: Color(0xfff0eae0),
      surfaceContainerHigh: Color(0xffeae3d9),
      surfaceContainerHighest: Color(0xffe4ddd3),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: JalaBrand.amberLight,
      surfaceTint: JalaBrand.amberLight,
      onPrimary: Color(0xff462a00),
      primaryContainer: Color(0xff623f00),
      onPrimaryContainer: Color(0xffffddba),
      secondary: JalaBrand.amberLight,
      onSecondary: Color(0xff462a00),
      secondaryContainer: Color(0xff5a3700),
      onSecondaryContainer: Color(0xffffddba),
      tertiary: Color(0xffe6bdaa),
      onTertiary: Color(0xff442a1c),
      tertiaryContainer: Color(0xff5d4030),
      onTertiaryContainer: Color(0xffffdcc2),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      // Fondo oscuro cálido (no negro puro) - tono café oscuro
      surface: Color(0xff241f18),
      onSurface: Color(0xffeae1d6),
      onSurfaceVariant: Color(0xffcfc0b0),
      outline: Color(0xff9d8d7d),
      outlineVariant: Color(0xff51463b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeae1d6),
      onInverseSurface: Color(0xff352f28),
      inversePrimary: Color(0xff8a5100),
      surfaceDim: Color(0xff1a1610),
      surfaceBright: Color(0xff3c352e),
      surfaceContainerLowest: Color(0xff15110d),
      surfaceContainerLow: Color(0xff2a241c),
      surfaceContainer: Color(0xff2e2820),
      surfaceContainerHigh: Color(0xff39332a),
      surfaceContainerHighest: Color(0xff443d34),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  ThemeData theme(ColorScheme colorScheme) {
    final bool isLight = colorScheme.brightness == Brightness.light;

    final Color accentText =
        isLight ? JalaBrand.amberDeep : JalaBrand.amberLight;

    final Color inputFocusColor =
        isLight ? JalaBrand.ink : JalaBrand.amberDeep;

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    final baseText = textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    final refinedText = baseText.copyWith(
      displayLarge: baseText.displayLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.0),
      displayMedium: baseText.displayMedium
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8),
      displaySmall: baseText.displaySmall
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineLarge: baseText.headlineLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: baseText.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
      headlineSmall: baseText.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: refinedText,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: inputFocusColor, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: refinedText.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentText,
          textStyle: refinedText.labelLarge
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: refinedText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLowest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      appBarTheme: AppBarThemeData(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: refinedText.titleLarge,
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: refinedText.bodyMedium
            ?.copyWith(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: JalaBrand.amber.withValues(alpha: isLight ? 0.15 : 0.25),
        labelStyle: refinedText.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: refinedText.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: refinedText.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: refinedText.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: JalaBrand.amber,
        linearTrackColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
        linearMinHeight: 4,
        borderRadius: BorderRadius.circular(2),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        modalBackgroundColor: colorScheme.surface,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        showDragHandle: true,
        dragHandleColor: colorScheme.outline,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: refinedText.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: refinedText.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: JalaBrand.amber,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: JalaBrand.amber.withValues(alpha: isLight ? 0.15 : 0.25),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return refinedText.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: JalaBrand.amber,
            );
          }
          return refinedText.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: JalaBrand.amber, size: 24);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
      ),
    );
  }
}