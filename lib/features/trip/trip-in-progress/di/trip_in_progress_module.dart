import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_module.dart';
import '../data/remote/trip_api.dart';
import '../data/stub_trip_tracking_service.dart';
import '../data/trip_repository_impl.dart';
import '../domain/repositories/trip_repository.dart';
import '../domain/services/trip_tracking_service.dart';

final tripApiProvider = Provider<TripApi>((ref) {
  return TripApi(ref.watch(apiClientProvider));
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepositoryImpl(ref.watch(tripApiProvider));
});

final tripTrackingServiceProvider = Provider<TripTrackingService>((ref) {
  return StubTripTrackingService();
});
