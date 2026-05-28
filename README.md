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
├── main.dart                              ← entry point + bootstrap de toda la DI
├── app.dart                               ← MaterialApp + theme + rutas
│
├── core/                                  ← cosas transversales a TODA la app
│   ├── env/api_config.dart                ← lee API_BASE_URL del compile-time env
│   ├── http/
│   │   ├── api_client.dart                ← wrapper de http.Client, inyecta JWT
│   │   └── api_exception.dart             ← excepciones tipadas (Unauthorized, Validation, etc.)
│   └── storage/
│       ├── auth_storage.dart              ← interfaz abstracta
│       └── secure_auth_storage.dart       ← implementación con flutter_secure_storage
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
└── features/
    ├── splash/
    │   └── presentation/splash_screen.dart
    │
    ├── auth/                              ← LOGIN + REGISTER
    │   ├── data/
    │   │   ├── remote/auth_api.dart       ← HTTP datasource (rutas como constantes)
    │   │   ├── mappers/register_params_mapper.dart
    │   │   └── auth_repository_impl.dart  ← orquesta remote + mappers + storage
    │   ├── domain/
    │   │   ├── entities/register_params.dart    ← value object puro (sin toJson)
    │   │   └── repositories/auth_repository.dart  ← contrato abstracto
    │   └── presentation/
    │       ├── provider/                  ← los ChangeNotifier (LoginViewModel, RegisterViewModel)
    │       └── screens/                   ← los Widgets
    │
    └── profile/                           ← CRUD del usuario autenticado
        ├── data/
        │   ├── remote/profile_api.dart
        │   ├── mappers/profile_photo_upload_ticket_mapper.dart
        │   └── profile_repository_impl.dart
        ├── domain/
        │   ├── entities/profile_photo_upload_ticket.dart
        │   └── repositories/profile_repository.dart
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
flutter test      # smoke test del arranque
```

---

## Lo que queda pendiente

- **`data/local/`**: cuando agreguemos cache (perfil offline, lista de viajes recientes) va aquí.
- **HTTPS en producción**: hoy el backend responde por `http://` plano. En `release` Android bloquea cleartext — hay que configurar `network_security_config.xml` o ponerle HTTPS al servidor.
- **Refresh token**: el backend emite un JWT con expiración de 7 días sin refresh. Cuando se venza, el `UnauthorizedException` que ya manejamos manda al usuario a Login. Si se quiere algo más fino (refresh transparente), va aquí.
- **Tests unitarios** de viewmodels: el smoke test actual solo verifica que la app monta. Los ViewModels son `ChangeNotifier`s puros — son fáciles de testear con fakes del repositorio.

---

## Créditos

Proyecto Integrador del 9° cuatrimestre — desarrollado por el equipo:
- **Eduardo Uriel Chávez Díaz** 

