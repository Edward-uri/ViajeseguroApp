import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff8f4e00),
      surfaceTint: Color(0xff8f4e00),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffff8f00),
      onPrimaryContainer: Color(0xff623400),
      secondary: Color(0xff004378),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff005b9f),
      onSecondaryContainer: Color(0xffb3d3ff),
      tertiary: Color(0xffad2c00),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffd34011),
      onTertiaryContainer: Color(0xfffffbff),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffcf8f7),
      onSurface: Color(0xff1c1b1b),
      onSurfaceVariant: Color(0xff564334),
      outline: Color(0xff897362),
      outlineVariant: Color(0xffdcc1ae),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xffffb77a),
      primaryFixed: Color(0xffffdcc2),
      onPrimaryFixed: Color(0xff2e1500),
      primaryFixedDim: Color(0xffffb77a),
      onPrimaryFixedVariant: Color(0xff6d3a00),
      secondaryFixed: Color(0xffd3e4ff),
      onSecondaryFixed: Color(0xff001c38),
      secondaryFixedDim: Color(0xffa1c9ff),
      onSecondaryFixedVariant: Color(0xff004880),
      tertiaryFixed: Color(0xffffdbd1),
      onTertiaryFixed: Color(0xff3b0900),
      tertiaryFixedDim: Color(0xffffb5a0),
      onTertiaryFixedVariant: Color(0xff872000),
      surfaceDim: Color(0xffddd9d8),
      surfaceBright: Color(0xfffcf8f7),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f3f2),
      surfaceContainer: Color(0xfff1edec),
      surfaceContainerHigh: Color(0xffebe7e6),
      surfaceContainerHighest: Color(0xffe5e2e1),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffb87b),
      surfaceTint: Color(0xffffb77a),
      onPrimary: Color(0xff4c2700),
      primaryContainer: Color(0xffff8f00),
      onPrimaryContainer: Color(0xff623400),
      secondary: Color(0xffa1c9ff),
      onSecondary: Color(0xff00325b),
      secondaryContainer: Color(0xff005b9f),
      onSecondaryContainer: Color(0xffb3d3ff),
      tertiary: Color(0xffffb5a0),
      onTertiary: Color(0xff601400),
      tertiaryContainer: Color(0xfffb5b2d),
      onTertiaryContainer: Color(0xff170200),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff141313),
      onSurface: Color(0xffe5e2e1),
      onSurfaceVariant: Color(0xffdcc1ae),
      outline: Color(0xffa48c7a),
      outlineVariant: Color(0xff564334),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff8f4e00),
      primaryFixed: Color(0xffffdcc2),
      onPrimaryFixed: Color(0xff2e1500),
      primaryFixedDim: Color(0xffffb77a),
      onPrimaryFixedVariant: Color(0xff6d3a00),
      secondaryFixed: Color(0xffd3e4ff),
      onSecondaryFixed: Color(0xff001c38),
      secondaryFixedDim: Color(0xffa1c9ff),
      onSecondaryFixedVariant: Color(0xff004880),
      tertiaryFixed: Color(0xffffdbd1),
      onTertiaryFixed: Color(0xff3b0900),
      tertiaryFixedDim: Color(0xffffb5a0),
      onTertiaryFixedVariant: Color(0xff872000),
      surfaceDim: Color(0xff141313),
      surfaceBright: Color(0xff3a3938),
      surfaceContainerLowest: Color(0xff0e0e0e),
      surfaceContainerLow: Color(0xff1c1b1b),
      surfaceContainer: Color(0xff201f1f),
      surfaceContainerHigh: Color(0xff2a2a29),
      surfaceContainerHighest: Color(0xff353434),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.surface,
        canvasColor: colorScheme.surface,
      );
}
