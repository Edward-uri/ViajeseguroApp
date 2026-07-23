import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/domain/entities/user.dart';

class CurrentUserNotifier extends StateNotifier<User?> {
  CurrentUserNotifier() : super(null);

  void setUser(User user) => state = user;

  void clear() => state = null;

  User? get user => state;
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, User?>((ref) {
  return CurrentUserNotifier();
});

/// Version de la foto de perfil. Se incrementa al subir una nueva para
/// invalidar el cache de `AuthImageProvider` (cacheado por userId, que nunca
/// cambia) y forzar la recarga en el menu y en la pantalla de perfil.
final profilePhotoVersionProvider = StateProvider<int>((ref) => 0);
