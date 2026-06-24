import '../../domain/entities/trip_history_item.dart';

abstract class TripHistoryRepository {
  Future<List<TripHistoryItem>> getTripHistory();
}
