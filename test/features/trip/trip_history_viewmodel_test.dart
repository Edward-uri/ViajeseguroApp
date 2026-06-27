import 'package:flutter_test/flutter_test.dart';
import 'package:viajeseguroapp/features/trip/trip-history/domain/entities/trip_history_item.dart';
import 'package:viajeseguroapp/features/trip/trip-history/domain/repositories/trip_history_repository.dart';
import 'package:viajeseguroapp/features/trip/trip-history/presentation/provider/trip_history_viewmodel.dart';

class _StubTripHistoryRepository implements TripHistoryRepository {
  _StubTripHistoryRepository(this.items);
  final List<TripHistoryItem> items;
  @override
  Future<List<TripHistoryItem>> getTripHistory() async => items;
}

TripHistoryItem _item(DateTime fecha) => TripHistoryItem(
      id: fecha.toIso8601String(),
      fecha: fecha,
      tipo: 'viaje',
      estado: TripHistoryStatus.completado,
      originAddress: 'A',
      destinationAddress: 'B',
      tarifa: 50,
      metodoPago: 'Efectivo',
    );

void main() {
  group('TripHistoryViewModelState - igualdad por valor', () {
    test('estados con la misma lista (misma referencia) son iguales', () {
      const a = TripHistoryViewModelState();
      final b = a.copyWith();
      expect(b, equals(a));
    });

    test('cambiar totalEsteMes produce un estado distinto', () {
      const a = TripHistoryViewModelState();
      expect(a.copyWith(totalEsteMes: 3), isNot(equals(a)));
    });
  });

  group('TripHistoryViewModel.loadHistory', () {
    test('precalcula totalEsteMes contando solo los viajes del mes/año actual', () async {
      final now = DateTime.now();
      final esteMes = _item(DateTime(now.year, now.month, 1, 9));
      final esteMes2 = _item(DateTime(now.year, now.month, 2, 10));
      final mesPasado = _item(DateTime(now.year, now.month - 1, 15));

      final vm = TripHistoryViewModel(
        _StubTripHistoryRepository([esteMes, esteMes2, mesPasado]),
      );

      await vm.loadHistory();

      expect(vm.state.items.length, 3);
      expect(vm.state.totalEsteMes, 2);
      expect(vm.state.isLoading, false);
    });
  });
}
