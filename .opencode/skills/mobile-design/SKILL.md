---
name: mobile-design
description: Proporciona guías y mejores prácticas de diseño móvil en Flutter siguiendo Material Design 3 y los lineamientos del proyecto Jala. Usa cuando se creen o modifiquen pantallas, componentes UI, layouts responsive, o se necesite validar espaciados, tipografía, colores y accesibilidad en la app móvil.
---

# Diseño Móvil en Flutter

## Principios generales

### Jerarquía visual

1. **Un punto focal por pantalla**: El elemento más importante debe destacar
2. **Agrupación por proximidad**: Elementos relacionados deben estar juntos
3. **Contraste suficiente**: Texto sobre fondo debe tener ratio mínimo 4.5:1
4. **Consistencia**: Mismos patrones en toda la app

### Touch targets (áreas táctiles)

- **Mínimo**: 48x48 dp (recomendado por Google)
- **Ideal**: 52-56 dp para botones principales
- **Espaciado entre targets**: 8 dp mínimo

```dart
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: Icon(Icons.menu),
    onPressed: () {},
  ),
)
```

## Layouts responsive

### SafeArea

Siempre envolver contenido en `SafeArea` para respetar notches y barras del sistema:

```dart
Scaffold(
  body: SafeArea(
    child: // contenido
  ),
)
```

### MediaQuery para adaptaciones

```dart
final screenWidth = MediaQuery.of(context).size.width;
final isSmall = screenWidth < 360;
final isTablet = screenWidth > 600;

Padding(
  padding: EdgeInsets.symmetric(
    horizontal: isSmall ? 16 : 24,
  ),
)
```

### LayoutBuilder para widgets adaptativos

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 400) {
      return Column(...);
    } else {
      return Row(...);
    }
  },
)
```

## Espaciados consistentes

### Escala de espaciados (múltiplos de 4)

```dart
const double spacing4 = 4;
const double spacing8 = 8;
const double spacing12 = 12;
const double spacing16 = 16;
const double spacing24 = 24;
const double spacing32 = 32;
const double spacing48 = 48;
```

### Padding de pantalla

- **Horizontal**: 24 dp (estándar del proyecto)
- **Vertical**: 16-32 dp según contexto

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
)
```

### Espaciado entre elementos

- **Títulos y subtítulos**: 8 dp
- **Secciones**: 24-32 dp
- **Elementos relacionados**: 8-12 dp
- **Grupos separados**: 24 dp

## Tipografía móvil

### Escala tipográfica (Material 3)

```dart
final textTheme = Theme.of(context).textTheme;

// Títulos grandes
textTheme.displayLarge     // 57sp - Hero
textTheme.displayMedium    // 45sp - Pantalla
textTheme.displaySmall     // 36sp - Sección

// Títulos
textTheme.headlineLarge    // 32sp
textTheme.headlineMedium   // 28sp
textTheme.headlineSmall    // 24sp

// Cuerpo
textTheme.titleLarge       // 22sp
textTheme.titleMedium      // 16sp
textTheme.bodyLarge        // 16sp
textTheme.bodyMedium       // 14sp
textTheme.bodySmall        // 12sp

// Labels
textTheme.labelLarge       // 14sp
textTheme.labelMedium      // 12sp
textTheme.labelSmall       // 11sp
```

### Reglas de uso

- **Títulos de pantalla**: `headlineMedium` o `headlineSmall`
- **Subtítulos**: `titleMedium` o `titleSmall`
- **Cuerpo de texto**: `bodyLarge` o `bodyMedium`
- **Labels de inputs**: `labelLarge`
- **Texto secundario**: `bodySmall` con `colorScheme.onSurfaceVariant`

### Longitudes de línea

- **Máximo**: 60-70 caracteres por línea para legibilidad
- **Usar** `ConstrainedBox` o `SizedBox` con `maxWidth`

```dart
ConstrainedBox(
  constraints: BoxConstraints(maxWidth: 600),
  child: Text('Texto largo...'),
)
```

## Colores y temas

### Sistema de colores del proyecto

```dart
final colorScheme = Theme.of(context).colorScheme;

// Primarios
colorScheme.primary         // Color principal
colorScheme.onPrimary       // Texto sobre primario
colorScheme.primaryContainer

// Superficie
colorScheme.surface         // Fondo de pantallas
colorScheme.onSurface       // Texto principal
colorScheme.onSurfaceVariant // Texto secundario

// Error
colorScheme.error           // Mensajes de error
colorScheme.errorContainer  // Fondo de errores
colorScheme.onErrorContainer

// Outline
colorScheme.outline         // Bordes
colorScheme.outlineVariant  // Bordes sutiles
```

### Colores de marca (JalaBrand)

```dart
import '../../../theme/theme.dart';

JalaBrand.amber       // #FF8F00 - Naranja primario
JalaBrand.amberDeep   // #9A5200 - Naranja oscuro
JalaBrand.amberLight  // #FFB066 - Naranja claro
JalaBrand.ink         // #231D17 - Negro/Ink
JalaBrand.cream       // #FBF7F2 - Crema
```

### Contraste de colores

- **Texto normal**: Ratio mínimo 4.5:1
- **Texto grande (>18sp)**: Ratio mínimo 3:1
- **Elementos interactivos**: Ratio mínimo 3:1

## Componentes Material 3

### Botones

```dart
// Primario - Acción principal
FilledButton(
  onPressed: () {},
  child: Text('Continuar'),
)

// Secundario - Acciones menos importantes
OutlinedButton(
  onPressed: () {},
  child: Text('Cancelar'),
)

// Terciario - Acciones de bajo énfasis
TextButton(
  onPressed: () {},
  child: Text('Ver más'),
)

// Con icono
FilledButton.icon(
  onPressed: () {},
  icon: Icon(Icons.add),
  label: Text('Agregar'),
)
```

### Campos de texto

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Correo electrónico',
    hintText: 'ejemplo@correo.com',
    prefixIcon: Icon(Icons.email),
    suffixIcon: Icon(Icons.clear),
    border: OutlineInputBorder(),
  ),
)
```

### Cards

```dart
Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: colorScheme.outlineVariant),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(...),
  ),
)
```

### Bottom sheets

```dart
showModalBottomSheet(
  context: context,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (context) => Padding(
    padding: EdgeInsets.all(24),
    child: Column(...),
  ),
);
```

## Patrones de navegación móvil

### Bottom navigation

```dart
Scaffold(
  bottomNavigationBar: NavigationBar(
    selectedIndex: _currentIndex,
    onDestinationSelected: (index) {
      setState(() => _currentIndex = index);
    },
    destinations: [
      NavigationDestination(icon: Icon(Icons.home), label: 'Inicio'),
      NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
      NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
    ],
  ),
)
```

### App bars

```dart
AppBar(
  title: Text('Título'),
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => Navigator.pop(context),
  ),
  actions: [
    IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
  ],
)
```

## Accesibilidad móvil

### Semántica

```dart
Semantics(
  label: 'Botón de inicio',
  hint: 'Toca para ir al inicio',
  button: true,
  child: IconButton(
    icon: Icon(Icons.home),
    onPressed: () {},
  ),
)
```

### Excluir decoración

```dart
ExcludeSemantics(
  child: Icon(Icons.star, color: Colors.amber),
)
```

### Texto escalable

Usar `sp` (scale-independent pixels) para texto, nunca `px` fijo:

```dart
Text(
  'Texto',
  style: TextStyle(fontSize: 16), // ✅ Usa sp automáticamente
)
```

## Checklist de diseño móvil

- [ ] ¿Usaste `SafeArea` para respetar notches?
- [ ] ¿Los touch targets son al menos 48x48 dp?
- [ ] ¿El padding horizontal es consistente (24 dp)?
- [ ] ¿Usaste `textTheme` en lugar de estilos hardcodeados?
- [ ] ¿Usaste `colorScheme` en lugar de colores hardcodeados?
- [ ] ¿El contraste de texto es suficiente (4.5:1)?
- [ ] ¿Los espaciados siguen la escala (4, 8, 16, 24, 32)?
- [ ] ¿Probaste en pantallas pequeñas (360 dp)?
- [ ] ¿Los textos largos tienen `maxLines` y `overflow`?
- [ ] ¿Los botones principales usan `FilledButton`?
