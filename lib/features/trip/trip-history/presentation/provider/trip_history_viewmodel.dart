import 'package:equatable/equatable.dart';
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
      state = state.copyWith(
        items: items,
        isLoading: false,
        totalEsteMes: _contarEsteMes(items),
      );
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

  static int _contarEsteMes(List<TripHistoryItem> items) {
    final now = DateTime.now();
    return items
        .where((item) =>
            item.fecha.month == now.month && item.fecha.year == now.year)
        .length;
  }
}

class TripHistoryViewModelState extends Equatable {
  const TripHistoryViewModelState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.totalEsteMes = 0,
  });

  final List<TripHistoryItem> items;
  final bool isLoading;
  final String? errorMessage;

  // Precalculado al cargar (antes era un getter que filtraba toda la lista
  // y llamaba DateTime.now() en cada build).
  final int totalEsteMes;

  TripHistoryViewModelState copyWith({
    List<TripHistoryItem>? items,
    bool? isLoading,
    String? errorMessage,
    int? totalEsteMes,
  }) {
    return TripHistoryViewModelState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      totalEsteMes: totalEsteMes ?? this.totalEsteMes,
    );
  }

  @override
  List<Object?> get props => [items, isLoading, errorMessage, totalEsteMes];
}

final tripHistoryViewModelProvider =
    StateNotifierProvider<TripHistoryViewModel, TripHistoryViewModelState>((ref) {
  return TripHistoryViewModel(ref.watch(tripHistoryRepositoryProvider));
});
