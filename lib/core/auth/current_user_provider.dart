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
