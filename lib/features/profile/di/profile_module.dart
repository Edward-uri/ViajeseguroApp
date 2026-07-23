import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_module.dart';
import '../data/profile_repository_impl.dart';
import '../data/remote/profile_api.dart';
import '../domain/repositories/profile_repository.dart';

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(
    ref.watch(apiClientProvider),
    ref.watch(httpClientProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    ref.watch(profileApiProvider),
    ref.watch(authStorageProvider),
  );
});
