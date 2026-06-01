import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../core/http/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../data/auth_repository_impl.dart';
import '../data/remote/auth_api.dart';
import '../domain/repositories/auth_repository.dart';

/// Cableado de dependencias del feature de autenticacion.
///
/// Expone su grafo (api + repositorio) para que el composition root solo tenga
/// que componerlo, sin conocer la capa `data/`.
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
      ];
}
