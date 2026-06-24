import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/http/api_exception.dart';
import '../../di/trip_history_module.dart';
import '../../domain/entities/trip_history_item.dart';
import '../../domain/repositories/trip_history_repository.dart';

class TripHistoryViewModel extends StateNotifier<TripHistoryViewModelState> {
  TripHistoryViewModel(this._repository)
      : super(const TripHistoryViewModelState());

  final TripHistoryRepository _repository;

  Future<void> loadHistory() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.getTripHistory();
      state = state.copyWith(items: items, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo cargar el historial',
      );
    }
  }

  void clearError() {
    if (state.errorMessage == null) return;
    state = state.copyWith(errorMessage: null);
  }
}

class TripHistoryViewModelState {
  const TripHistoryViewModelState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<TripHistoryItem> items;
  final bool isLoading;
  final String? errorMessage;

  int get totalEsteMes {
    final now = DateTime.now();
    return items
        .where((item) =>
            item.fecha.month == now.month && item.fecha.year == now.year)
        .length;
  }

  TripHistoryViewModelState copyWith({
    List<TripHistoryItem>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TripHistoryViewModelState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final tripHistoryViewModelProvider =
    StateNotifierProvider<TripHistoryViewModel, TripHistoryViewModelState>((ref) {
  return TripHistoryViewModel(ref.watch(tripHistoryRepositoryProvider));
});
