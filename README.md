# Jala — App móvil

Cliente Flutter de **Jala**, una plataforma de moto-taxis. Esta app es la del **pasajero** (la del conductor irá en un binario aparte cuando le toque su turno). Apunta principalmente a Android y consume un backend REST en Node/Express que vive aparte.

---

## Stack

| Pieza | Para qué |
|---|---|
| **Flutter** + **Dart** | Toda la app |
| **Material 3** | Sistema de diseño base. El `ColorScheme` viene del Material Theme Builder oficial |
| **Provider** | State management + Inyección de Dependencias manual |
| **http** | Cliente HTTP — **una sola instancia** compartida en toda la app |
| **flutter_secure_storage** | Persistir el JWT en el Keystore de Android (encriptado a nivel hardware) |
| **google_fonts** | Cargar **Plus Jakarta Sans** sin tener que pegar los `.ttf` en el repo |
| **flutter_svg** | Renderizar el logo de la marca como vector |
| **image_picker** | Elegir foto de perfil desde galería o cámara |
| **firebase_core** | Inicialización de Firebase |
| **firebase_messaging** | Push notifications vía FCM (remote wipe) |
| **geolocator** | Detectar ubicaciones mock en Android |
| **device_preview** | Probar la UI en distintos devices sin emulador (solo activo en web/desktop debug) |

---

## Arquitectura

La app combina **tres ideas** que se complementan:

### 1. Clean Architecture (capas)

Cada feature tiene tres capas con reglas estrictas de dependencia:

```
┌──────────────────────────┐
│      presentation/       │  Widgets + ChangeNotifier (lo que ve el usuario)
└────────────┬─────────────┘
             │ depende de
             ▼
┌──────────────────────────┐
│         domain/          │  Entidades puras + contratos (interfaces)
└────────────▲─────────────┘
             │ implementa
┌────────────┴─────────────┐
│          data/           │  Datasources HTTP + mappers JSON
└──────────────────────────┘
```

- **`domain/`** no sabe que existe Flutter, ni JSON, ni HTTP. Es Dart puro.
- **`presentation/`** depende **solo del `domain/`**, nunca de `data/` directo.
- **`data/`** implementa los contratos del `domain/` y se ocupa del mundo real (HTTP, almacenamiento).

¿Por qué? Porque así puedo cambiar el backend, los mappers, o hasta migrar a otro cliente HTTP, **sin tocar la UI ni los viewmodels**. La UI solo conoce una interfaz abstracta, no la implementación.

### 2. Vertical Slicing (por feature)

En vez de tener una carpeta global `viewmodels/`, otra `repositories/`, otra `screens/`, agrupo todo por **feature**:

```
features/
├── auth/         ← todo lo de login + registro vive aquí dentro
└── profile/      ← todo lo del perfil del usuario vive aquí dentro
```

Cada feature es **autónoma** — si mañana quiero borrar `profile/` completo, lo elimino y nada más se rompe (excepto las rutas y la DI que la consumían). Esto facilita:
- Sumar features nuevas sin tocar lo existente.
- Que cada integrante del equipo trabaje en una feature distinta sin pisarse.
- Razonar sobre el código: si el bug es de login, el bug vive en `features/auth/`, no en 5 carpetas dispersas.

### 3. Screaming Architecture

Cuando abres `lib/`, **la estructura te grita de qué se trata la app**, no qué framework usa:

```
lib/
├── features/
│   ├── auth/        ← "Hay autenticación"
│   ├── profile/     ← "Hay perfil de usuario"
│   └── splash/      ← "Hay pantalla de splash"
```

No hay carpetas tipo `controllers/`, `services/`, `viewmodels/` en la raíz. Esas existen pero **adentro** de cada feature, porque son detalles de implementación. Lo importante (el dominio del problema) está al frente.

### MVVM dentro de cada feature

Cada feature aplica **Model-View-ViewModel**:

- **View** = el `Widget` de Flutter (la pantalla y sus pedacitos). No tiene lógica de negocio, solo dibuja según el estado.
- **ViewModel** = un `ChangeNotifier` que expone el estado y los comandos. No conoce widgets ni `BuildContext`.
- **Model** = las entidades del `domain/` (`User`, `RegisterParams`, etc.).

La View se suscribe al ViewModel con `context.watch<XxxViewModel>()` y se reconstruye cuando el ViewModel hace `notifyListeners()`. Cuando la View se desmonta, el ViewModel se libera (porque está scopeado al `ChangeNotifierProvider` de esa pantalla). Cero leaks.

> Decidí llamar a la carpeta **`provider/`** en vez de `viewmodels/` porque refleja la tecnología que está usando (el paquete Provider). Las clases adentro mantienen el sufijo `ViewModel` porque conceptualmente siguen siendo ViewModels de MVVM. La carpeta dice **cómo**, las clases dicen **qué**.

---

## Estructura de carpetas

```
lib/
├── main.dart                              ← entry point + bootstrap de toda la DI + Firebase init
├── app.dart                               ← MaterialApp + theme + rutas
├── firebase_options.dart                  ← config de Firebase por plataforma (desde .env)
│
├── core/                                  ← cosas transversales a TODA la app
│   ├── di/
│   │   └── core_module.dart               ← providers app-wide (http, storage, api)
│   ├── env/api_config.dart                ← lee API_BASE_URL del compile-time env
│   ├── http/
│   │   ├── api_client.dart                ← wrapper de http.Client, inyecta JWT
│   │   └── api_exception.dart             ← excepciones tipadas (Network, Unauthorized, Validation…)
│   ├── messaging/
│   │   ├── push_messaging_service.dart            ← interfaz abstracta FCM
│   │   ├── firebase_push_messaging_service.dart   ← impl con firebase_messaging
│   │   └── background_message_handler.dart        ← handler en isolate background
│   ├── navigation/
│   │   └── app_navigator.dart             ← GlobalKey<NavigatorState> para navegar sin context
│   ├── security/
│   │   └── remote_wipe_handler.dart       ← borrado remoto de datos sensibles vía FCM
│   ├── storage/
│   │   ├── auth_storage.dart              ← interfaz abstracta
│   │   ├── secure_auth_storage.dart       ← impl con flutter_secure_storage
│   │   ├── sensitive_data_storage.dart           ← interfaz abstracta (datos sensibles)
│   │   ├── secure_sensitive_data_storage.dart    ← impl con flutter_secure_storage
│   │   ├── sensitive_data_seeder.dart            ← siembra datos demo al primer inicio
│   │   └── sensitive_data_debug.dart             ← helper debug del storage
│   └── widgets/
│       └── logo_badge.dart                ← widget reutilizable del logo
│
├── shared/                                ← lo que comparten varias features
│   ├── domain/entities/user.dart          ← entidad User (puro, sin JSON)
│   └── data/mappers/user_mapper.dart      ← User ↔ JSON
│
├── theme/                                 ← Material 3
│   ├── theme.dart                         ← ColorScheme light/dark + InputDecorationTheme
│   └── util.dart                          ← helper para cargar la fuente Plus Jakarta Sans
│
├── routes/app_routes.dart                 ← constantes de nombres de ruta
│
├── assets/
│   └── logo.svg                           ← logo vectorial de la marca
│
├── config/
│   ├── dev.json                           ← config de desarrollo (localhost:3000)
│   ├── prod.example.json                  ← plantilla de producción (git-tracked)
│   └── prod.json                          ← config real de producción (git-ignored)
│
├── docs/
│   └── superpowers/specs/                 ← documentos de diseño adicionales
│
└── features/                              ← vertical slicing
    ├── splash/
    │   └── presentation/splash_screen.dart ← splash animado + decisión de ruta
    │
    ├── auth/                              ← LOGIN + REGISTER
    │   ├── data/
    │   │   ├── remote/auth_api.dart       ← HTTP datasource
    │   │   ├── mappers/register_params_mapper.dart
    │   │   ├── platform/
    │   │   │   ├── mock_location_detector_impl.dart  ← MethodChannel Android
    │   │   │   └── usb_debug_detector_impl.dart      ← MethodChannel Android
    │   │   └── auth_repository_impl.dart  ← orquesta remote + mappers + storage
    │   ├── domain/
    │   │   ├── entities/register_params.dart    ← value object puro
    │   │   ├── repositories/auth_repository.dart  ← contrato abstracto
    │   │   └── services/
    │   │       ├── mock_location_detector.dart    ← interfaz abstracta
    │   │       └── usb_debug_detector.dart        ← interfaz abstracta
    │   ├── di/
    │   │   └── auth_module.dart           ← providers del feature auth
    │   └── presentation/
    │       ├── provider/                  ← ChangeNotifier (LoginViewModel, RegisterViewModel)
    │       └── screens/                   ← Widgets de pantalla
    │
    └── profile/                           ← CRUD del usuario autenticado
        ├── data/
        │   ├── remote/profile_api.dart
        │   ├── mappers/profile_photo_upload_ticket_mapper.dart
        │   └── profile_repository_impl.dart
        ├── domain/
        │   ├── entities/profile_photo_upload_ticket.dart
        │   └── repositories/profile_repository.dart
        ├── di/
        │   └── profile_module.dart        ← providers del feature profile
        └── presentation/
            ├── provider/
            └── screens/
```

> **¿Por qué `data/remote/` y no solo `data/`?** Porque preparé el terreno para cuando agreguemos cache local. Cuando llegue ese momento, va a vivir en `data/local/` (por ejemplo `data/local/auth_cache.dart` con `SharedPreferences` o `sqflite`) y el `repository_impl` va a orquestar las dos fuentes. Hoy solo tenemos `remote/`, pero la división ya está hecha.

---

## Decisiones técnicas (con el porqué)

### 1. Una sola instancia de `http.Client` para toda la app

Se crea en `main.dart` y se inyecta vía Provider a todos los repositorios. No quiero tener un `http.Client` por feature porque eso significa:
- Mantener varios connection pools abiertos a la vez (desperdicio).
- Inconsistencia en timeouts y headers.

Cuando la app se cierra, el `Provider` llama al `dispose` y cierra el cliente liberando el connection pool.

### 2. DI manual con Provider (sin codegen)

La cátedra exige Provider. Coincide con la idea de "DI manual" porque Provider **no es un framework de DI con magia** — es un `InheritedWidget` glorificado. Tú armas el árbol, tú decides qué se inyecta dónde.

Hay dos niveles de scope:

- **Nivel app-wide** (en `main.dart` con `MultiProvider`): cosas que viven mientras la app esté abierta — `http.Client`, `ApiClient`, `AuthStorage`, repositorios.
- **Nivel pantalla** (con `ChangeNotifierProvider`): ViewModels. Se crean cuando entras a la pantalla, se destruyen cuando sales. Así el estado de un Login no contamina al siguiente Login.

### 3. `shared/` para entidades compartidas

`User` lo usan **dos features**: `auth` lo crea al loguear/registrar, `profile` lo lee/actualiza. Si lo dejaba en `features/auth/`, entonces `profile` tenía que importar de `auth` — y eso rompe el vertical slicing (las features dejan de ser autónomas).

Solución: lo subí a `lib/shared/domain/entities/user.dart`. Ambas features lo importan desde `shared/`, ninguna depende de la otra.

### 4. Mappers en `data/` (domain puro)

El `domain/` no debería saber qué formato usa el backend. Si mañana el backend cambia de JSON a Protobuf, **mi domain no debería enterarse**.

Por eso saqué `fromJson`/`toJson` de `User`, `RegisterParams` y `ProfilePhotoUploadTicket`. Esa lógica vive en clases dedicadas dentro de `data/mappers/`:

```dart
// shared/data/mappers/user_mapper.dart
class UserMapper {
  static User fromJson(Map<String, dynamic> json) { ... }
  static Map<String, dynamic> toJson(User user) { ... }
}
```

Las entidades quedan limpias, sin `import 'dart:convert'`, sin nada de serialización.

### 5. Variables de entorno con `--dart-define-from-file`

Para la URL del backend (que cambia entre dev y producción) **no usé `flutter_dotenv`**. Razones:

- `flutter_dotenv` empaqueta el `.env` como **asset** dentro del APK — cualquiera que descomprima el binario lo lee.
- `--dart-define-from-file` (oficial de Flutter desde 3.7) inyecta los valores **en compile-time**, dentro del binario compilado. No queda archivo plano.
- Es compile-time safe: si me equivoco en el nombre de una variable, el compilador no me deja pasar.

Los archivos viven en `config/`. `prod.example.json` se sube al repo como plantilla; `prod.json` (con la IP real del EC2) está en `.gitignore` porque cambia seguido en Learner Lab y no quiero hacer commits cada vez.

Para correr la app contra el backend de producción:
```
flutter run --dart-define-from-file=config/prod.json
```

### 6. JWT en `flutter_secure_storage`

No uso `SharedPreferences` para el token. En Android, `flutter_secure_storage` lo guarda en el **Keystore** — encriptado a nivel del hardware del dispositivo. Es lo que se defiende como buena práctica para tokens en una entrevista.

El `AuthStorage` es una interfaz abstracta en `core/storage/`. La implementación concreta (`SecureAuthStorage`) está aparte. Así, si mañana quiero probar con otro mecanismo (o mockear en tests), cambio la implementación sin tocar el resto.

### 7. Material 3 con el Theme Builder oficial

La paleta no la inventé a mano — la generé en el [Material Theme Builder](https://m3.material.io/theme-builder) a partir de cuatro semillas:

- **Primary**: `#FF8F00` (ámbar)
- **Secondary**: `#005B9F` (cobalto)
- **Tertiary**: `#D84315` (barro)
- **Neutral**: `#FDFBF7` (crema)

El Theme Builder me devolvió un `ColorScheme` con ~50 tokens (primary, primaryContainer, onPrimary, surface, onSurface, error, etc.) ya con la armonía correcta. En el código nunca escribo hex pelado — siempre uso `Theme.of(context).colorScheme.X`, lo cual significa que **la app tiene dark mode gratis** y se va a respetar cualquier ajuste futuro de paleta.

Además agregué un `InputDecorationTheme` global con `borderRadius: 8`. Así todos los `TextField` de la app comparten el mismo redondeo sin tener que repetirlo en cada widget.

### 8. FLAG_SECURE nativo (sin paquete)

La cátedra pedía que el SO bloquee capturas de pantalla en el Login. Lo resolví con código **nativo de Android**, no con paquete:

```kotlin
// MainActivity.kt
window.setFlags(
    WindowManager.LayoutParams.FLAG_SECURE,
    WindowManager.LayoutParams.FLAG_SECURE,
)
```

¿Por qué nativo y no `flutter_windowmanager` o similar?
- Cero dependencia extra.
- Se activa al arrancar la `MainActivity`, antes de que cualquier código Dart se ejecute.
- Es lo que recomienda la doc oficial de Android.

A nivel sistema operativo: intentar screenshot muestra "No se puede capturar por política de seguridad", la grabación de pantalla queda en negro, y la app aparece como un cuadro negro en el switcher de recientes. **Sin mostrar ningún cartel de "pantalla protegida"** — la seguridad se hace, no se anuncia.

### 9. Navigation 1.0 (named routes)

La cátedra pidió Navigator 1.0, no `go_router` ni Navigator 2.0. Las rutas viven como constantes en `routes/app_routes.dart`:

```dart
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
}
```

Y se registran en `MaterialApp.routes`. La navegación es con `Navigator.pushNamed`, `Navigator.pushReplacementNamed` y `Navigator.pushNamedAndRemoveUntil` (para limpiar el stack en login/logout).

### 10. Excepciones tipadas, no `Result<T, E>`

Mi `ApiClient` lanza excepciones específicas según el caso:

- `NetworkException`: sin internet, timeout, DNS.
- `UnauthorizedException`: 401 (JWT vencido).
- `ValidationException`: 400/422 (datos inválidos).
- `ApiException`: cualquier otro error del backend.

El ViewModel hace `try/catch` y traduce a `errorMessage` para la UI. Pensé en usar el patrón `Result<T, E>` (más funcional, más explícito) pero es más boilerplate y menos idiomático en Dart. Las excepciones tipadas + `on XxxException catch` me dan el mismo control con menos código.

---

## Patrones de diseño

Más allá de Clean Architecture y MVVM, la app aplica estos patrones de forma consistente:

| Patrón | Dónde aparece | Para qué sirve |
|--------|---------------|----------------|
| **Repository** | `AuthRepository` / `AuthRepositoryImpl`, `ProfileRepository` / `ProfileRepositoryImpl` | Interfaz en domain, implementación en data. El dominio nunca sabe cómo se obtienen los datos. |
| **Factory** | `CoreModule.providers()`, `AuthModule.providers()`, `ProfileModule.providers()` | Métodos estáticos que construyen y configuran la cadena de dependencias. |
| **Singleton** | `http.Client`, `ApiClient`, `AuthStorage`, `SensitiveDataStorage`, repositorios | Una sola instancia compartida en toda la app, inyectada vía `MultiProvider`. |
| **Strategy** | `AuthStorage` / `SecureAuthStorage`, `SensitiveDataStorage` / `SecureSensitiveDataStorage` | La interfaz define el contrato; se puede intercambiar la implementación (real, mock, otra tecnología). |
| **Adapter** | `UserMapper`, `RegisterParamsMapper`, `ProfilePhotoUploadTicketMapper` | Convierte entre entidades de dominio (puras) y el formato del backend (JSON), manteniendo el dominio aislado. |
| **Bridge** | `MockLocationDetector` / `MockLocationDetectorImpl`, `UsbDebugDetector` / `UsbDebugDetectorImpl` | Interfaz abstracta en domain, implementación nativa Android via `MethodChannel`. El domain no depende de Flutter ni de Android. |
| **Value Object** | `RegisterParams`, `ProfilePhotoUploadTicket` | Objetos inmutables que encapsulan datos sin identidad propia. |
| **Global Key / Mediator** | `AppNavigator` | Singleton con `GlobalKey<NavigatorState>` que permite navegar desde código que no tiene `BuildContext` (por ejemplo, el handler de notificaciones FCM en segundo plano). |
| **Data Seeder** | `SensitiveDataSeeder` | Siembra datos de demostración en el primer inicio, siguiendo el patrón Strategy para no acoplar la siembra al storage concreto. |

---

## Flujo de autenticación

```
[1] Arranque
    main() crea http.Client + ApiClient + AuthStorage en MultiProvider
    MaterialApp.home → SplashScreen

[2] SplashScreen
    Lee JWT del secure storage
    ├─ Hay token  → Navigator.pushReplacementNamed('/profile')
    └─ No hay     → Navigator.pushReplacementNamed('/login')

[3] LoginScreen
    LoginViewModel.submit()
      → AuthRepository.login()
        → ApiClient.post('/api/auth/login', {identifier, password})
        → AuthStorage.writeToken(jwt)
        → devuelve User
    Si OK → Navigator.pushReplacementNamed('/profile')

[4] ProfileScreen
    ProfileViewModel.loadProfile()
      → ProfileRepository.getMe()
        → ApiClient.get('/api/users/me')  (con Bearer en automático)
        → devuelve User con foto pre-firmada de S3

[5] Logout
    AuthStorage.clear()
    Navigator.pushNamedAndRemoveUntil('/login', stack vacío)
```

El `ApiClient` agrega el header `Authorization: Bearer <jwt>` **automáticamente** leyéndolo del `AuthStorage` en cada request. Ningún viewmodel ni screen tiene que preocuparse del token — eso vive en la infraestructura.

---

## Seguridad

### Detección de riesgos en el login

Antes de dejar al usuario autenticarse, `LoginViewModel` ejecuta una verificación de seguridad del dispositivo Android via `MethodChannel`:

```
LoginScreen → LoginViewModel.checkSecurity()
  ├── MockLocationDetector (MethodChannel + Geolocator)
  │     └─ ¿GPS mockeado? → bloquea login
  └── UsbDebugDetector (MethodChannel)
        └─ ¿USB debugging activo? → bloquea login
```

Si se detecta cualquiera de los dos riesgos, la pantalla muestra un bloqueo con **cuenta regresiva de 5 segundos** y cierra la sesión automáticamente. La app no permite login en dispositivos comprometidos.

Las interfaces (`MockLocationDetector`, `UsbDebugDetector`) viven en `features/auth/domain/services/` (Dart puro). Las implementaciones concretas viven en `features/auth/data/platform/` y usan `MethodChannel` para hablar con el código Kotlin nativo de Android.

### FLAG_SECURE nativo (sin paquete)

Como se detalla en la decisión técnica #8, la `MainActivity.kt` de Android activa `FLAG_SECURE` al arrancar, antes de que cualquier código Dart se ejecute. Bloquea capturas de pantalla, grabación y previsualización en el switcher de apps.

### Remote wipe vía FCM

La app incluye un mecanismo de **borrado remoto** mediante Firebase Cloud Messaging.

Cuando el servidor envía una notificación push con data payload indicando un wipe, el `RemoteWipeHandler` se ejecuta (incluso si la app está en segundo plano) y:

1. Borra todos los datos sensibles almacenados (username, email, teléfono, session token, user ID).
2. Borra el JWT de autenticación.
3. Resetea el flag de "datos ya sembrados".
4. Navega al login limpiando el stack.

Esto se orquesta desde:
- `core/security/remote_wipe_handler.dart` — lógica de borrado.
- `core/messaging/firebase_push_messaging_service.dart` — suscripción FCM + recepción de mensajes.
- `core/messaging/background_message_handler.dart` — callback en isolate background para mensajes FCM cuando la app está cerrada.
- `core/storage/sensitive_data_storage.dart` + `secure_sensitive_data_storage.dart` — almacenamiento encriptado de los 5 campos sensibles.

---

## Cómo correr el proyecto

### Primera vez

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Copiar la plantilla de config y poner tu URL del backend
cp config/prod.example.json config/prod.json
# Edita config/prod.json y reemplaza la URL placeholder
```

### Desde Android Studio (mi flujo)

1. **Run → Edit Configurations…** → selecciona tu config de Flutter.
2. En **"Additional run args"** pon:
   ```
   --dart-define-from-file=config/prod.json
   ```
3. **Apply → OK.**
4. Botón ▶ y a correr.

### Desde la línea de comandos

```bash
# Contra producción (EC2):
flutter run --dart-define-from-file=config/prod.json

# Build APK release:
flutter build apk --release --dart-define-from-file=config/prod.json
```

### Pruebas

```bash
flutter analyze   # static analysis, debe decir "No issues found!"
flutter test      # corre tests unitarios y widget tests
```

La suite de tests se organiza así:

| Archivo | Tipo | Qué prueba |
|---------|------|------------|
| `test/widget_test.dart` | Widget smoke test | Verifica que la app monta y muestra el branding "Jala" en el SplashScreen. Usa fakes de `AuthStorage`, `AuthRepository`, `MockLocationDetector` y `ProfileRepository`. |
| `test/features/auth/login_viewmodel_test.dart` | Unit test | 4 casos: mock location detectado, USB debug detectado, sin riesgos, y estado inicial. Usa stubs con contadores de llamadas. |

Los ViewModels son `ChangeNotifier`s puros sin dependencia de Flutter, lo que los hace directamente testeables inyectando fakes de sus repositorios.

---

## Lo que queda pendiente

- **`data/local/`**: cuando agreguemos cache (perfil offline, lista de viajes recientes) va aquí.
- **HTTPS en producción**: hoy el backend responde por `http://` plano. En `release` Android bloquea cleartext — hay que configurar `network_security_config.xml` o ponerle HTTPS al servidor.
- **Refresh token**: el backend emite un JWT con expiración de 7 días sin refresh. Cuando se venza, el `UnauthorizedException` que ya manejamos manda al usuario a Login. Si se quiere algo más fino (refresh transparente), va aquí.
- **Tests de RegisterViewModel y ProfileViewModel**: hoy solo hay tests de `LoginViewModel`. Los otros dos ViewModels siguen el mismo patrón y son igualmente testeables.
- **Integración y E2E**: no hay tests de integración (widget tests con dependencias reales) ni end-to-end.
- **Suscripción a topics FCM**: el remote wipe está implementado del lado del cliente, pero falta que el servidor envíe la notificación push al topic correcto.

---

## Créditos

Proyecto Integrador del 9° cuatrimestre — desarrollado por el equipo:
- **Eduardo Uriel Chávez Díaz** 

