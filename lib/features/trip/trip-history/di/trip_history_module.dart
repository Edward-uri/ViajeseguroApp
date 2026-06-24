import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_module.dart';
import '../data/remote/trip_history_api.dart';
import '../data/trip_history_repository_impl.dart';
import '../domain/repositories/trip_history_repository.dart';

final tripHistoryApiProvider = Provider<TripHistoryApi>((ref) {
  return TripHistoryApi(ref.watch(apiClientProvider));
});

final tripHistoryRepositoryProvider = Provider<TripHistoryRepository>((ref) {
  return TripHistoryRepositoryImpl(ref.watch(tripHistoryApiProvider));
});
