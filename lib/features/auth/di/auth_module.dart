import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../core/http/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../data/auth_repository_impl.dart';
import '../data/platform/mock_location_detector_impl.dart';
import '../data/remote/auth_api.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/services/mock_location_detector.dart';

class AuthModule {
  const AuthModule._();

  static List<SingleChildWidget> providers() => <SingleChildWidget>[
        Provider<AuthApi>(
          create: (ctx) => AuthApi(ctx.read<ApiClient>()),
        ),
        Provider<AuthRepository>(
          create: (ctx) => AuthRepositoryImpl(
            ctx.read<AuthApi>(),
            ctx.read<AuthStorage>(),
          ),
        ),
        Provider<MockLocationDetector>(
          create: (_) => MockLocationDetectorImpl(),
        ),
      ];
}
