import 'package:flutter_test/flutter_test.dart';
import 'package:viajeseguroapp/features/trip/trip-searching/domain/entities/trip_location.dart';
import 'package:viajeseguroapp/features/trip/trip-searching/presentation/provider/trip_searching_viewmodel.dart';

void main() {
  group('TripSearchingViewModelState - igualdad por valor (Equatable)', () {
    test('dos estados por defecto son iguales', () {
      expect(
        const TripSearchingViewModelState(),
        equals(const TripSearchingViewModelState()),
      );
      expect(
        const TripSearchingViewModelState().hashCode,
        const TripSearchingViewModelState().hashCode,
      );
    });

    test('copyWith() sin cambios produce un estado IGUAL (clave para deduplicar rebuilds)', () {
      const original = TripSearchingViewModelState();
      final copia = original.copyWith();
      expect(copia, equals(original));
      // Sin Equatable esto seria false (identidad distinta) y Riverpod
      // reconstruiria la UI aunque nada cambio.
    });

    test('cambiar un campo produce un estado DISTINTO', () {
      const original = TripSearchingViewModelState();
      final cambiado = original.copyWith(isSearching: true);
      expect(cambiado, isNot(equals(original)));
    });

    test('cambiar solo pendingMapLat no afecta la igualdad de isPickingOnMap (lo que aisla el mapa)', () {
      const original = TripSearchingViewModelState(isPickingOnMap: true);
      final tras = original.copyWith(pendingMapLat: 19.43);
      // El estado completo cambia (lat distinta)...
      expect(tras, isNot(equals(original)));
      // ...pero el valor que observa el mapa via .select sigue igual.
      expect(tras.isPickingOnMap, equals(original.isPickingOnMap));
    });

    test('estados con el mismo origin (misma referencia) siguen siendo iguales', () {
      const loc = TripLocation(address: 'Centro', latitude: 19.4, longitude: -99.1);
      const a = TripSearchingViewModelState(origin: loc);
      final b = a.copyWith();
      expect(b, equals(a));
    });
  });
}
