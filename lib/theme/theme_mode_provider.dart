import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Modo de tema elegido por el usuario (claro/oscuro/sistema), persistido
/// entre sesiones. `MaterialApp.themeMode` lo observa, así que cambiarlo
/// re-tematiza toda la app al instante.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  // ponytail: se reusa flutter_secure_storage (ya es dependencia) en lugar de
  // agregar shared_preferences solo para esta clave.
  static const _storage = FlutterSecureStorage();
  static const _key = 'theme_mode';

  Future<void> _load() async {
    try {
      final saved = await _storage.read(key: _key);
      if (saved != null && mounted) {
        state = ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
      }
    } catch (_) {
      // Sin preferencia guardada: se queda en sistema.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(key: _key, value: mode.name);
    } catch (_) {}
  }
}
