import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../http/api_client.dart';
import '../navigation/app_navigator.dart';
import '../storage/auth_storage.dart';
import '../storage/secure_auth_storage.dart';
import '../storage/secure_sensitive_data_storage.dart';
import '../storage/sensitive_data_storage.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  ref.onDispose(() => ref.state.close());
  return http.Client();
});

final authStorageProvider = Provider<AuthStorage>((ref) {
  return SecureAuthStorage();
});

final sensitiveDataStorageProvider = Provider<SensitiveDataStorage>((ref) {
  return SecureSensitiveDataStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    ref.watch(httpClientProvider),
    ref.watch(authStorageProvider),
    onAuthFailure: AppNavigator.goToLogin,
  );
});
