import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_module.dart';
import '../../../core/http/api_client.dart';
import '../../../core/routes/api_routes.dart';

/// Reporta al conductor de un viaje. El backend deriva a quién se reporta (y su
/// rol) según quién hace la petición; un reporte basta para bloquear el par.
class ReportesApi {
  ReportesApi(this._api);

  final ApiClient _api;

  Future<void> reportar({
    required int idViaje,
    required String motivo,
    String? comentario,
  }) =>
      _api.post(
        ApiRoutes.reportes,
        body: <String, dynamic>{
          'idViaje': idViaje,
          'motivo': motivo,
          if (comentario != null && comentario.trim().isNotEmpty)
            'comentario': comentario.trim(),
        },
        auth: true,
      );
}

final reportesApiProvider = Provider<ReportesApi>(
  (ref) => ReportesApi(ref.watch(apiClientProvider)),
);
