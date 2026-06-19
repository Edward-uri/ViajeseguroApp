---
name: figma-flutter
description: Genera código Flutter desde diseños de Figma siguiendo la arquitectura limpia del proyecto (MVVM + Provider). Usa cuando el usuario proporcione enlaces de Figma o solicite implementar pantallas desde diseños. Mapea colores, tipografía y espaciados al tema existente.
---

# Figma a Flutter

## Flujo de trabajo

1. **Recibir enlace de Figma**: El usuario proporciona un enlace como `https://www.figma.com/design/xxxxx/...`
2. **Extraer datos con MCP**: Usa `get_figma_data` o `get_figma_node` para obtener el diseño
3. **Descargar imágenes**: Llama `download_figma_images` para obtener assets antes de generar código
4. **Generar código**: Crea los archivos siguiendo la arquitectura limpia del proyecto

## Arquitectura de features

Cada feature sigue esta estructura:

```
lib/features/{feature_name}/
├── data/
│   ├── {feature}_repository_impl.dart
│   ├── mappers/
│   ├── remote/
│   └── platform/
├── di/
│   └── {feature}_di.dart
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── services/
└── presentation/
    ├── provider/
    │   └── {feature}_viewmodel.dart
    └── screens/
        └── {feature}_screen.dart
```

## Convenciones de código

### ViewModels (Provider)

```dart
import 'package:flutter/foundation.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  
  LoginViewModel(this._authRepository);
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _authRepository.login(email, password);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Screens

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Contenido
            ],
          ),
        ),
      ),
    );
  }
}
```

## Mapeo de colores de Figma

### Colores de marca (JalaBrand)

Cuando encuentres estos colores en Figma, mapea a las constantes existentes:

| Figma Color | Constante | Hex |
|-------------|-----------|-----|
| Naranja primario | `JalaBrand.amber` | `#FF8F00` |
| Naranja oscuro | `JalaBrand.amberDeep` | `#9A5200` |
| Naranja claro | `JalaBrand.amberLight` | `#FFB066` |
| Negro/Ink | `JalaBrand.ink` | `#231D17` |
| Crema | `JalaBrand.cream` | `#FBF7F2` |

### Sistema de colores Material 3

Usa los colores del `ColorScheme` del tema:

```dart
final colorScheme = Theme.of(context).colorScheme;

// En lugar de colores hardcodeados:
Color(color: Color(0xFF231D17)) // ❌ Mal
colorScheme.primary              // ✅ Bien
colorScheme.surface              // ✅ Bien
colorScheme.onSurface            // ✅ Bien
colorScheme.error                // ✅ Bien
```

## Tipografía

Usa `textTheme` del tema, no definas estilos manualmente:

```dart
final textTheme = Theme.of(context).textTheme;

Text(
  'Título',
  style: textTheme.headlineMedium, // ✅ Bien
)

Text(
  'Título',
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // ❌ Mal
)
```

## Espaciados y dimensiones

Convierte valores de Figma (px) a dp de Flutter:

- **Padding/Margin**: Usa `EdgeInsets.all(16.0)`, `EdgeInsets.symmetric(horizontal: 24.0)`
- **Tamaños comunes**:
  - Botones: altura 52-54px
  - Inputs: altura 52-56px
  - Padding pantalla: 24px horizontal
  - Espaciado entre elementos: 8, 16, 24, 32px
  - Border radius: 12, 14, 20px

## Componentes reutilizables

Usa los widgets de Material 3 ya configurados en el tema:

### Botones

```dart
// Botón primario (FilledButton)
FilledButton(
  onPressed: () {},
  child: const Text('Continuar'),
)

// Botón secundario (OutlinedButton)
OutlinedButton(
  onPressed: () {},
  child: const Text('Cancelar'),
)

// Botón de texto (TextButton)
TextButton(
  onPressed: () {},
  child: const Text('¿Olvidaste tu contraseña?'),
)
```

### Inputs

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Correo electrónico',
    hintText: 'ejemplo@correo.com',
    prefixIcon: const Icon(Icons.email),
  ),
)
```

### Cards

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [],
    ),
  ),
)
```

## Imágenes y assets

1. **Descarga imágenes de Figma** con `download_figma_images`
2. **Guarda en** `assets/images/` o `assets/icons/`
3. **Referencia en código**:

```dart
Image.asset('assets/images/logo.png')
SvgPicture.asset('assets/icons/icon.svg')
```

## Estados de pantalla

Maneja estados con sealed classes para múltiples estados:

```dart
sealed class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess();
}

class LoginError extends LoginState {
  final String message;
  const LoginError(this.message);
}
```

## Checklist antes de entregar

- [ ] ¿Usaste colores del `colorScheme` en lugar de valores hardcodeados?
- [ ] ¿Usaste `textTheme` para estilos de texto?
- [ ] ¿Creaste el ViewModel con `ChangeNotifier`?
- [ ] ¿Registraste el Provider en el árbol de widgets?
- [ ] ¿Descargaste las imágenes necesarias?
- [ ] ¿Seguiste la estructura de carpetas de la feature?
- [ ] ¿Usaste componentes de Material 3 (FilledButton, OutlinedButton, etc.)?

## Ejemplo completo

Al recibir un enlace de Figma:

```
Implementa esta pantalla: https://www.figma.com/design/xxxxx/Login-Screen
```

1. Extrae datos: `get_figma_data(fileKey: "xxxxx", nodeId: "123:456")`
2. Descarga imágenes: `download_figma_images(...)`
3. Crea archivos:
   - `lib/features/auth/presentation/screens/login_screen.dart`
   - `lib/features/auth/presentation/provider/login_viewmodel.dart`
4. Usa colores del tema, tipografía del tema, y componentes Material 3
5. Registra el Provider en el sistema de DI
