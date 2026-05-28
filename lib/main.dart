import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/env/api_config.dart';
import 'core/http/api_client.dart';
import 'core/storage/auth_storage.dart';
import 'core/storage/secure_auth_storage.dart';
import 'features/auth/data/auth_repository_impl.dart';
import 'features/auth/data/remote/auth_api.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/profile/data/profile_repository_impl.dart';
import 'features/profile/data/remote/profile_api.dart';
import 'features/profile/domain/repositories/profile_repository.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final http.Client httpClient = http.Client();
  final AuthStorage authStorage = SecureAuthStorage();

  final ApiClient apiClient = ApiClient(httpClient, authStorage);

  final AuthApi authApi = AuthApi(apiClient);
  final ProfileApi profileApi = ProfileApi(apiClient, httpClient);

  final AuthRepository authRepository =
      AuthRepositoryImpl(authApi, authStorage);
  final ProfileRepository profileRepository = ProfileRepositoryImpl(profileApi);

  if (kDebugMode) {
    debugPrint('[Jala] API baseUrl = ${ApiConfig.baseUrl}');
  }


  runApp(
    MultiProvider(
      providers: [
        Provider<http.Client>(
          create: (_) => httpClient,
          dispose: (_, c) => c.close(),
        ),
        Provider<AuthStorage>.value(value: authStorage),
        Provider<ApiClient>.value(value: apiClient),

        Provider<AuthRepository>.value(value: authRepository),
        Provider<ProfileRepository>.value(value: profileRepository),
      ],
      child: DevicePreview(
        enabled: _shouldEnableDevicePreview(),
        builder: (context) => const JalaApp(),
      ),
    ),
  );
}

bool _shouldEnableDevicePreview() {
  if (kReleaseMode) return false;
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}
