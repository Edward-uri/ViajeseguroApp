# ViajeSeguro — App móvil

Aplicación móvil del pasajero para ViajeSeguro, una plataforma de moto-taxis orientada a Suchiapa, Chiapas.

## Funcionalidades

- registro e inicio de sesión;
- gestión del perfil del pasajero;
- consumo de la API REST de ViajeSeguro;
- almacenamiento seguro del token de autenticación;
- navegación preparada para crecer por funcionalidades.

## Stack

- Flutter
- Dart
- Material 3
- Provider
- Clean Architecture
- MVVM
- `http`
- `flutter_secure_storage`
- `flutter_svg`
- `image_picker`

## Arquitectura

El proyecto combina Clean Architecture, vertical slicing y MVVM:

```
lib/
├── core/                  # Utilidades y configuración compartida
├── features/
│   ├── auth/              # Registro, login y sesión
│   ├── profile/           # Perfil del usuario
│   └── splash/            # Pantalla inicial
├── main.dart              # Arranque y composición de dependencias
└── app.dart               # Tema, rutas y configuración de la app
```

La capa de dominio no depende de Flutter, HTTP ni JSON. La presentación consume contratos del dominio, mientras que la capa de datos implementa las llamadas al backend y el almacenamiento local.

## Ejecución local

### Requisitos

- Flutter SDK
- Dart SDK
- Android Studio o un dispositivo/emulador
- Backend de ViajeSeguro configurado

### Instalación

```bash
git clone https://github.com/Edward-uri/ViajeseguroApp.git
cd ViajeseguroApp
flutter pub get
flutter run
```

Configura las variables y certificados locales siguiendo los archivos de ejemplo del proyecto. No publiques tokens, certificados privados ni credenciales.

## Ecosistema

- [Frontend web](https://github.com/Edward-uri/VIAJESEGURO)
- [Backend REST](https://github.com/Edward-uri/ViajeseguroBackend)
- [Aplicación del conductor](https://github.com/Edward-uri/viajeSeguroConductor)
- [Servicio de rutas](https://github.com/Edward-uri/CalcularRutaServices)

## Estado

Proyecto académico/integrador en evolución.

## Autor

Eduardo Uriel Chavez Diaz — [@Edward-uri](https://github.com/Edward-uri)
