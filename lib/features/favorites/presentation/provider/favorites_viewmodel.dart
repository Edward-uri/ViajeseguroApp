import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_module.dart';
import '../../data/direcciones_api.dart';
import '../../domain/entities/direccion.dart';

class FavoritesViewModel extends StateNotifier<FavoritesState> {
  FavoritesViewModel(this._api) : super(const FavoritesState());

  final DireccionesApi _api;

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final raw = await _api.listar();
      state = state.copyWith(
        items: raw.map(Direccion.fromJson).toList(),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudieron cargar las direcciones',
      );
    }
  }

  Future<bool> crear({
    String? etiqueta,
    required double lat,
    required double lng,
    String? texto,
  }) async {
    try {
      await _api.crear(
        etiqueta: etiqueta,
        lat: lat,
        lng: lng,
        texto: texto,
        esFavorita: true,
      );
      await load();
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'No se pudo guardar la direccion');
      return false;
    }
  }

  Future<void> eliminar(int id) async {
    // Optimista: quitar de la lista de inmediato; si el backend falla, revertir.
    final previous = state.items;
    state = state.copyWith(
      items: previous.where((d) => d.id != id).toList(),
    );
    try {
      await _api.eliminar(id);
    } catch (_) {
      state = state.copyWith(
        items: previous,
        errorMessage: 'No se pudo eliminar la direccion',
      );
    }
  }
}

class FavoritesState extends Equatable {
  const FavoritesState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Direccion> items;
  final bool isLoading;
  final String? errorMessage;

  FavoritesState copyWith({
    List<Direccion>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FavoritesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [items, isLoading, errorMessage];
}

final direccionesApiProvider = Provider<DireccionesApi>((ref) {
  return DireccionesApi(ref.watch(apiClientProvider));
});

final favoritesViewModelProvider =
    StateNotifierProvider<FavoritesViewModel, FavoritesState>((ref) {
  return FavoritesViewModel(ref.watch(direccionesApiProvider));
});
