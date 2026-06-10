import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../http/api_client.dart';
import '../storage/auth_storage.dart';
import '../storage/secure_auth_storage.dart';
import '../storage/secure_sensitive_data_storage.dart';
import '../storage/sensitive_data_storage.dart';

/// Dependencias compartidas por toda la app (HTTP, almacenamiento, cliente API).
///
/// Se construyen de forma lazy: cada una se instancia la primera vez que un
/// feature la lee del contexto.
class CoreModule {
  const CoreModule._();

  static List<SingleChildWidget> providers() => <SingleChildWidget>[
        Provider<http.Client>(
          create: (_) => http.Client(),
          dispose: (_, c) => c.close(),
        ),
        Provider<AuthStorage>(
          create: (_) => SecureAuthStorage(),
        ),
        Provider<SensitiveDataStorage>(
          create: (_) => SecureSensitiveDataStorage(),
        ),
        Provider<ApiClient>(
          create: (ctx) => ApiClient(
            ctx.read<http.Client>(),
            ctx.read<AuthStorage>(),
          ),
        ),
      ];
}
