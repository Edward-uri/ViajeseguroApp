import '../domain/entities/trip_history_item.dart';
import '../domain/repositories/trip_history_repository.dart';
import 'remote/trip_history_api.dart';

class TripHistoryRepositoryImpl implements TripHistoryRepository {
  TripHistoryRepositoryImpl(this._api);

  final TripHistoryApi _api;

  @override
  Future<List<TripHistoryItem>> getTripHistory() async {
    final response = await _api.getTripHistory();
    final list = response['viajes'] as List<dynamic>? ??
        response['data'] as List<dynamic>? ??
        response['results'] as List<dynamic>? ??
        const [];

    return list
        .map((item) => TripHistoryItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
