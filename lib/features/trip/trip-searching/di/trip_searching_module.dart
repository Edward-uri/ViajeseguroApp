import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_module.dart';
import '../data/remote/mapbox_api.dart';
import '../data/trip_search_repository_impl.dart';
import '../domain/repositories/trip_search_repository.dart';

final mapboxApiProvider = Provider<MapboxApi>((ref) {
  return MapboxApi(ref.watch(httpClientProvider));
});

final tripSearchRepositoryProvider = Provider<TripSearchRepository>((ref) {
  return TripSearchRepositoryImpl(
    ref.watch(mapboxApiProvider),
    ref.watch(apiClientProvider),
  );
});
