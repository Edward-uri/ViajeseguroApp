---
name: flutter-best-practices
description: Verifica y aplica buenas practicas de Flutter y Dart en el proyecto ViajeseguroApp. Usa cuando se cree, modifique o revise codigo Flutter: widgets, ViewModels, repositorios, APIs, entidades o navegacion. Cubre arquitectura limpia (MVVM + Riverpod), gestion de estado, manejo de errores, nulabilidad, const, dispose, nombres y convenciones del proyecto. Respeta la arquitectura y flujo existentes.
---

# Buenas Practicas de Flutter - ViajeseguroApp

## Stack del proyecto

- **Flutter** (Dart ^3.11.5)
- **Gestion de estado**: `flutter_riverpod` (^2.6.1) con `StateNotifier` + `StateNotifierProvider`
- **Cliente HTTP**: `http` (^1.2.2) via `ApiClient` central
- **Storage seguro**: `flutter_secure_storage` para JWT/refresh/user
- **Mapas**: `mapbox_maps_flutter` (^2.4.0)
- **Ubicacion**: `geolocator` (^10.1.0)
- **Linting**: `flutter_lints` (^6.0.0)

## Arquitectura (Clean Architecture + MVVM)

Cada feature sigue esta estructura obligatoria:

```
lib/features/{feature}/
├── data/
│   ├── {feature}_repository_impl.dart    # impl del repositorio
│   ├── mappers/                          # mappers JSON <-> entidad
│   ├── remote/                           # APIs HTTP ({feature}_api.dart)
│   └── platform/                         # detectores/platform channels
├── di/
│   └── {feature}_module.dart             # providers de Riverpod
├── domain/
│   ├── entities/                         # entidades puras (sin Flutter)
│   ├── repositories/                     # abstract class {Feature}Repository
│   └── services/                         # interfaces de servicios
└── presentation/
    ├── provider/
    │   └── {feature}_viewmodel.dart      # StateNotifier + estado inmutable
    └── screens/
        └── {feature}_screen.dart         # ConsumerStatefulWidget/ConsumerWidget
```

### Reglas de capas

1. **domain** NO depende de Flutter ni de data. Entidades y repositorios abstractos solo.
2. **data** implementa los repositorios de domain y maneja HTTP/storage.
3. **presentation** consume ViewModels via Riverpod, nunca llama al API directamente.
4. **di** registra providers que conectan las capas. Toda dependencia se inyecta via `ref.watch`.

### Flujo de dependencias

```
Screen (ConsumerWidget)
  -> ref.watch(xViewModelProvider)
    -> ViewModel (StateNotifier)
      -> Repository (abstract)
        -> Api (data/remote) -> ApiClient -> http
```

## ViewModels (StateNotifier)

### Estructura obligatoria

```dart
class XViewModel extends StateNotifier<XViewModelState> {
  XViewModel(this._repo) : super(const XViewModelState());

  final XRepository _repo;
}

class XViewModelState {
  const XViewModelState({
    this.isLoading = false,
    this.errorMessage,
    this.data,
  });

  final bool isLoading;
  final String? errorMessage;
  final Entity? data;

  XViewModelState copyWith({
    bool? isLoading,
    String? errorMessage,
    Entity? data,
  }) {
    return XViewModelState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      data: data ?? this.data,
    );
  }
}

final xViewModelProvider =
    StateNotifierProvider<XViewModel, XViewModelState>((ref) {
  return XViewModel(ref.watch(xRepositoryProvider));
});
```

### Reglas

- El estado debe ser **inmutable** con `const` en el constructor por defecto.
- Usar `copyWith` para actualizar el estado, NUNCA mutar campos.
- Antes de operaciones async, poner `isLoading: true` y limpiar `errorMessage`.
- Capturar `ApiException` para mensajes especificos, `catch (_)` para genericos.
- Si el ViewModel usa timers o streams, hacer `cancel()`/`close()` en `dispose()`.
- NO mezclar logica de UI (navigation, snackbars) dentro del ViewModel. El ViewModel retorna datos/bools y la Screen decide la navegacion.

## Pantallas (Screens)

### ConsumerStatefulWidget

```dart
class XScreen extends ConsumerStatefulWidget {
  const XScreen({super.key});

  @override
  ConsumerState<XScreen> createState() => _XScreenState();
}

class _XScreenState extends ConsumerState<XScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(xViewModelProvider.notifier).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(xViewModelProvider);
    return Scaffold(...);
  }
}
```

### Reglas

- Usar `ConsumerWidget` si no necesitas `initState`/`dispose`.
- Usar `ConsumerStatefulWidget` si necesitas lifecycle o controllers.
- `ref.watch` para reconstruir UI, `ref.read` para acciones puntuales.
- Verificar `mounted` despues de operaciones async antes de `setState` o navegacion.
- Verificar `context.mounted` antes de usar `context` despues de un `await`.
- Liberar recursos (`TextEditingController`, `FocusNode`, `AnimationController`) en `dispose()`.

## Nulabilidad y const

### const donde sea posible

```dart
// BIEN
const SizedBox(height: 16)
const EdgeInsets.symmetric(horizontal: 24)
const _LoginContent(onSubmit: _onSubmit);

// MAL
SizedBox(height: 16)  // sin const
```

### Nulabilidad

- Marcar como nullable (`?`) solo lo que genuinely puede ser null.
- Inicializar campos no nulos en el constructor.
- Usar `??` para defaults en lugar de `!` forzado.
- Evitar `!` (null assertion). Si se usa, justificar con comentario.

```dart
// BIEN
final nombre = user.nombreUsuario;
if (nombre.isEmpty) return 'Pasajero';

// EVITAR
final nombre = user!.nombreUsuario;  // crash si user es null
```

## Manejo de errores

### En el ViewModel

```dart
Future<bool> doSomething() async {
  state = state.copyWith(isLoading: true, errorMessage: null);
  try {
    final result = await _repo.fetch();
    state = state.copyWith(data: result, isLoading: false);
    return true;
  } on ApiException catch (e) {
    state = state.copyWith(isLoading: false, errorMessage: e.message);
    return false;
  } catch (_) {
    state = state.copyWith(
      isLoading: false,
      errorMessage: 'Ocurrio un error inesperado',
    );
    return false;
  }
}
```

### En la UI

- Mostrar `errorMessage` del ViewModel en un widget visible (banner, snackbar).
- NO usar `print()` ni `debugPrint()` para errores de API en produccion (solo debug).
- Los errores de red (`NetworkException`) ya tienen mensajes user-friendly.

## HTTP y ApiClient

- Toda peticion HTTP pasa por `ApiClient` (inyectado via `apiClientProvider`).
- Los endpoints se definen en `lib/core/routes/api_routes.dart` como `static const`.
- El `ApiClient` maneja **refresh automatico** al recibir 401: reintenta la peticion.
- Si el refresh falla, redirige a Login via `AppNavigator.goToLogin`.
- `auth: true` para endpoints protegidos, `auth: false` para publicos.

### Rutas API

```dart
abstract class ApiRoutes {
  ApiRoutes._();
  static const String xBase = '/api/x';
  static const String xCreate = xBase;
  static const String xEstimar = '$xBase/estimar';
}
```

- Constructor privado `._()` para evitar instanciacion.
- `static const String` para todas las rutas.
- Usar el idioma del backend (espanol: `/api/viajes`, no `/api/trips`).

## Storage y autenticacion

- JWT, refresh token y datos del usuario se guardan en `SecureAuthStorage`.
- El `currentUserProvider` (`lib/core/auth/current_user_provider.dart`) expone el usuario global.
- Tras login exitoso: guardar usuario en `currentUserProvider` y persistir en storage.
- Tras logout/refresh fallido: limpiar storage y redirigir a Login.

## Navegacion

- Rutas definidas en `lib/routes/app_routes.dart` como `static const String`.
- Transiciones via `PageTransitions` (`lib/core/widgets/page_transitions.dart`).
- Para navegacion global sin context: `AppNavigator.goToLogin()`.
- Usar `pushNamedAndRemoveUntil` para flujos que no deben volver atras (login -> home).

```dart
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRoutes.passengerHome,
  (route) => false,
);
```

## Widgets y UI

### Tema

- Usar `Theme.of(context).colorScheme` y `Theme.of(context).textTheme`.
- Colores de marca: `JalaBrand.amber`, `JalaBrand.ink`, `JalaBrand.cream`.
- NO hardcodear colores hex en widgets (usar `colorScheme` o `JalaBrand`).

### Widgets compartidos

- Los widgets reutilizables van en `lib/shared/widgets/` con prefijo `jala_`.
- Exportar via `widgets.dart` barrel.

### dispose

```dart
@override
void dispose() {
  _controller.dispose();
  _focusNode.dispose();
  _timer?.cancel();
  super.dispose();
}
```

## Naming conventions

| Elemento             | Convencion       | Ejemplo                     |
| -------------------- | ---------------- | --------------------------- |
| Archivos             | snake_case       | `login_viewmodel.dart`      |
| Clases               | PascalCase       | `LoginViewModel`            |
| Providers            | camelCaseProvider| `loginViewModelProvider`    |
| Estados (ViewModel)  | XViewModelState  | `LoginViewModelState`       |
| Entidades            | PascalCase       | `Trip`, `User`              |
| Repos abstractos     | XRepository      | `AuthRepository`            |
| Repos impl           | XRepositoryImpl  | `AuthRepositoryImpl`        |
| APIs                 | XApi             | `AuthApi`                   |
| Screens              | XScreen          | `LoginScreen`               |
| Rutas                | camelCase static | `AppRoutes.login`           |
| Metodos async        | camelCase        | `loadUser()`, `confirmFare()`|
| Campos privados      | _camelCase       | `_correo`, `_repository`    |

## Checklist de verificacion

Antes de dar por terminada una feature, verificar:

### Arquitectura
- [ ] Las entidades de domain no importan nada de Flutter ni de data
- [ ] El repositorio abstracto esta en domain, la impl en data
- [ ] Los providers estan registrados en el module de DI
- [ ] El ViewModel no importa nada de data/remote directamente

### Estado
- [ ] El estado es inmutable con copyWith
- [ ] El constructor del estado tiene defaults con const
- [ ] isLoading se settea antes y despues de operaciones async
- [ ] errorMessage se limpia al iniciar y se settea en catch

### UI
- [ ] Se usa `ref.watch` para reconstruir, `ref.read` para acciones
- [ ] Se verifica `mounted`/`context.mounted` despues de awaits
- [ ] Los controllers/resources se liberan en dispose
- [ ] Se usa colorScheme/textTheme en lugar de hardcoded

### HTTP
- [ ] Las rutas estan en ApiRoutes como static const
- [ ] auth: true en endpoints protegidos
- [ ] Se captura ApiException para errores especificos
- [ ] No hay llamadas HTTP fuera del ApiClient

### Null safety
- [ ] No hay `!` sin justificacion
- [ ] Los campos nullable se inicializan como null
- [ ] Se usa `??` para defaults

### Const
- [ ] Widgets estaticos tienen const
- [ ] EdgeInsets/SizedBox con valores literales tienen const
- [ ] Constructores privados con `._()` tienen const

## Comandos de verificacion

```bash
flutter analyze       # errores y lints
flutter test          # tests unitarios y de widgets
```

Aplicar despues de cada cambio para asegurar que no se rompio nada.
