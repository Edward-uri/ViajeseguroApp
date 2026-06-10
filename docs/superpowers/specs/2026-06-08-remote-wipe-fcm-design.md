# Borrado remoto de datos sensibles vía FCM — Diseño

Fecha: 2026-06-08
Proyecto: viajeseguroApp (Jala)

## Objetivo

1. Crear un almacenamiento seguro con al menos 4 campos sensibles.
2. Asignar información a esos campos de forma automática.
3. Al recibir una notificación FCM **específica para ese usuario** (no general), eliminar
   el contenido de los datos sensibles y cerrar la sesión.

## Restricciones

- No modificar la arquitectura existente (Clean Architecture por feature + DI con `Provider`,
  patrón interfaz abstracta + implementación concreta en `core/`).
- No romper la ejecución actual en Windows (donde se desarrolla con `device_preview`).

## Estado actual relevante

- `core/storage/secure_auth_storage.dart` implementa `AuthStorage` y solo guarda el `jwt`.
- DI central en `core/di/core_module.dart` (`CoreModule.providers()`).
- Navegación con rutas nombradas en `app.dart`; logout usa `pushNamedAndRemoveUntil` a Login.
- `SplashScreen` decide la ruta inicial según `AuthRepository.hasSession()`.
- `firebase_core` ya está instalado; **falta `firebase_messaging`**.

## Diseño

### 1. Almacenamiento seguro (componente nuevo, paralelo al existente)

Se deja `SecureAuthStorage` intacto. Se agrega, siguiendo el mismo patrón:

- `core/storage/sensitive_data_storage.dart` — interfaz `SensitiveDataStorage`.
- `core/storage/secure_sensitive_data_storage.dart` — implementación con `FlutterSecureStorage`
  (`AndroidOptions(encryptedSharedPreferences: true)`).

Campos sensibles (5):

| Clave                      | Contenido                                       |
|----------------------------|-------------------------------------------------|
| `sensitive_username`       | nombre de usuario (dirige el topic FCM)         |
| `sensitive_email`          | correo electrónico                              |
| `sensitive_phone`          | teléfono                                        |
| `sensitive_session_token`  | token de sesión secundario                      |
| `sensitive_user_id`        | id del usuario                                  |

Métodos: `writeAll(...)`, lectores individuales, `readUsername()`, `clear()` (borra todas las claves).

### 2. Asignación automática (seeder)

`core/storage/sensitive_data_seeder.dart`: al iniciar la app, si el storage está vacío,
escribe valores demo automáticamente (incluye un `username`). Garantiza que siempre haya
datos sensibles que borrar, sin depender de un login real contra el backend.

### 3. Borrado remoto vía FCM (targeting por usuario)

Dependencia nueva: `firebase_messaging`.

- `core/messaging/push_messaging_service.dart` — interfaz.
- `core/messaging/firebase_push_messaging_service.dart` — implementación: solicita permisos,
  se suscribe al topic `wipe-<username>` del usuario almacenado, registra handlers.
- `core/security/remote_wipe_handler.dart` — valida el payload:
  `data['command'] == 'wipe_secure_data'` **y** `data['targetUser'] == username almacenado`.
  Si coincide: `SensitiveDataStorage.clear()` + `AuthStorage.clear()`.

Flujo según estado de la app:

- **Foreground** (`onMessage`): borra y navega a Login al instante mediante un `navigatorKey`
  global agregado al `MaterialApp`.
- **Background / app cerrada** (`onBackgroundMessage`, función top-level): borra el secure
  storage en el isolate (construye las implementaciones directamente, sin DI). Al reabrir, el
  `SplashScreen` ve `hasSession() == false` y navega a Login.

### 4. Guardas para no romper nada

- `firebase_messaging` no soporta Windows: toda la init FCM se envuelve en un guard de
  plataforma (solo Android/iOS/macOS/web). En Windows la app sigue igual que hoy.
- Los providers nuevos se registran en `CoreModule.providers()` sin tocar los existentes.
- En `main.dart` solo se agrega la init del seeder + FCM tras `Firebase.initializeApp`.

## Formato del mensaje FCM (data message)

```json
{
  "to": "/topics/wipe-<username>",
  "data": {
    "command": "wipe_secure_data",
    "targetUser": "<username>"
  }
}
```

Se usa **data message** (no `notification`) para que el handler se ejecute y controle el borrado
en todos los estados de la app.

## Plan de implementación

1. Agregar `firebase_messaging`.
2. `SensitiveDataStorage` (interfaz) + `SecureSensitiveDataStorage` (impl, 5 campos).
3. Seeder de datos automáticos.
4. Servicio FCM + handler de remote wipe (validación por usuario) + handler background top-level.
5. `navigatorKey` global cableado en `MaterialApp`.
6. Registrar providers nuevos en `CoreModule`.
7. Conectar todo en `main.dart` detrás del guard de plataforma.
8. `flutter analyze` para verificar.

## Criterios de éxito

- Existe almacenamiento seguro con ≥4 campos sensibles poblados automáticamente.
- Un mensaje FCM dirigido al topic/usuario correcto borra los datos sensibles y cierra sesión.
- Un mensaje dirigido a otro usuario NO borra nada (validación de `targetUser`).
- La app sigue compilando y ejecutando en Windows sin FCM.
