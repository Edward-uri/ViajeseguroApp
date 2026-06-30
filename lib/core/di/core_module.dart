import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../http/api_client.dart';
import '../navigation/app_navigator.dart';
import '../storage/auth_storage.dart';
import '../storage/secure_auth_storage.dart';
import '../storage/secure_sensitive_data_storage.dart';
import '../storage/sensitive_data_storage.dart';
import '../websocket/socket_service.dart';

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

/// Provider global del SocketService.
/// El token se lee dinámicamente desde el ApiClient (que lo cachea en memoria).
/// Si el token expira, el socket dispara un refresh via ApiClient y reconecta.
final socketServiceProvider = Provider<SocketService>((ref) {
  final client = ref.read(apiClientProvider);
  final service = SocketService(
    tokenProvider: () => client.currentToken ?? '',
    onTokenExpired: () async {
      // El ApiClient._tryRefreshToken es privado; usamos un truco:
      // hacemos un GET ligero que dispara el refresh si el token expiró.
      try {
        await client.get('/api/auth/refresh', auth: false);
        return client.currentToken != null && client.currentToken!.isNotEmpty;
      } catch (_) {
        return false;
      }
    },
  );
  ref.onDispose(() => service.dispose());
  return service;
});
