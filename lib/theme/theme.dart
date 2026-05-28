import "package:flutter/material.dart";


abstract final class JalaBrand {
  static const Color amber = Color(0xffff8f00);
  static const Color amberDeep = Color(0xff9a5200);

  static const Color amberLight = Color(0xffffb066);

  static const Color ink = Color(0xff231d17);

  static const Color cream = Color(0xfffbf7f2);
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
      surface: Color(0xff15110d),
      onSurface: Color(0xffeae1d6),
      onSurfaceVariant: Color(0xffd5c4b3),
      outline: Color(0xff9d8d7d),
      outlineVariant: Color(0xff51463b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffeae1d6),
      onInverseSurface: Color(0xff352f28),
      inversePrimary: Color(0xff8a5100),
      surfaceDim: Color(0xff15110d),
      surfaceBright: Color(0xff3c352e),
      surfaceContainerLowest: Color(0xff0f0c09),
      surfaceContainerLow: Color(0xff1d1813),
      surfaceContainer: Color(0xff211c16),
      surfaceContainerHigh: Color(0xff2c2620),
      surfaceContainerHighest: Color(0xff37302a),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  ThemeData theme(ColorScheme colorScheme) {
    final bool isLight = colorScheme.brightness == Brightness.light;

    final Color accentText =
        isLight ? JalaBrand.amberDeep : JalaBrand.amberLight;

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
          borderSide: const BorderSide(color: JalaBrand.amber, width: 2),
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
    );
  }
}