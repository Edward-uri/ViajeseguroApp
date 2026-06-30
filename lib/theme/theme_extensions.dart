import 'package:flutter/material.dart';

import 'theme.dart';

/// Extensiones para acceder fácilmente al tema desde cualquier widget.
///
/// Uso:
/// ```dart
/// final colors = context.colors;  // ColorScheme
/// final styles = context.text;     // TextTheme
/// final brand = context.brand;     // JalaBrand semantic colors
/// ```
extension BuildContextThemeX on BuildContext {
  /// ColorScheme del tema actual (light/dark automático)
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// TextTheme del tema actual
  TextTheme get text => Theme.of(this).textTheme;

  /// True si el tema actual es oscuro
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Colores semánticos del proyecto que adaptan automáticamente al modo oscuro
  JalaSemantic get brand => JalaSemantic.of(this);
}

/// Colores semánticos del proyecto Jala que se adaptan automáticamente
/// al modo claro/oscuro. No hardcodear hex en widgets.
class JalaSemantic {
  const JalaSemantic._(this._isDark);

  final bool _isDark;

  /// Obtiene la instancia correcta según el brightness del contexto
  static JalaSemantic of(BuildContext context) {
    return JalaSemantic._(
      Theme.of(context).brightness == Brightness.dark,
    );
  }

  /// Texto secundario (subtítulos, hints, captions)
  Color get greyDark =>
      _isDark ? JalaBrand.greyDarkDark : JalaBrand.greyDark;

  /// Placeholder / hint text
  Color get greyLight =>
      _isDark ? JalaBrand.greyLightDark : JalaBrand.greyLight;

  /// Bordes inactivos, drag handles
  Color get greyBorder =>
      _isDark ? JalaBrand.greyBorderDark : JalaBrand.greyBorder;

  /// Fondos claros (search bars, cards secundarios)
  Color get surfaceLight =>
      _isDark ? JalaBrand.surfaceLightDark : JalaBrand.surfaceLight;

  /// Dividers, progress track
  Color get divider =>
      _isDark ? JalaBrand.dividerDark : JalaBrand.divider;

  /// Fondo de acento amber (tarifa, iconos circulares)
  Color get accentSurface =>
      _isDark ? JalaBrand.accentSurfaceDark : JalaBrand.accentSurface;

  /// Azul para mapa / ubicación
  Color get accentBlue =>
      _isDark ? JalaBrand.accentBlueDark : JalaBrand.accentBlue;

  /// Verde para success / completado
  Color get success =>
      _isDark ? JalaBrand.successDark : JalaBrand.success;

  /// Fondo verde claro para badges de success
  Color get successLight =>
      _isDark ? JalaBrand.successLightDark : JalaBrand.successLight;

  /// Rojo/naranja para cancelar / eliminar / logout
  Color get destructive =>
      _isDark ? JalaBrand.destructiveDark : JalaBrand.destructive;

  /// Fondo rojo claro para badges de error
  Color get destructiveLight =>
      _isDark ? JalaBrand.destructiveLightDark : JalaBrand.destructiveLight;
}
