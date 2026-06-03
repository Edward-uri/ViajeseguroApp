import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../../core/http/api_client.dart';
import '../data/profile_repository_impl.dart';
import '../data/remote/profile_api.dart';
import '../domain/repositories/profile_repository.dart';

class ProfileModule {
  const ProfileModule._();

  static List<SingleChildWidget> providers() => <SingleChildWidget>[
        Provider<ProfileApi>(
          create: (ctx) => ProfileApi(
            ctx.read<ApiClient>(),
            ctx.read<http.Client>(),
          ),
        ),
        Provider<ProfileRepository>(
          create: (ctx) => ProfileRepositoryImpl(ctx.read<ProfileApi>()),
        ),
      ];
}
