---
name: material-theme
description: Aplica y respeta el Material Theme global de la app Jala. Usa cuando se creen o modifiquen pantallas, widgets, o componentes visuales. Garantiza consistencia de colores, tipografia y estilos usando Theme.of(context), colorScheme, textTheme y JalaBrand. NUNCA hardcodee colores hex.
---

# Material Theme - ViajeseguroApp

## Archivos del tema

| Archivo | Contenido |
|---------|-----------|
| `lib/theme/theme.dart` | `JalaBrand` (constantes de color) + `MaterialTheme` (construye `ThemeData`) |
| `lib/theme/theme_extensions.dart` | `BuildContextThemeX` extension + `JalaSemantic` (colores semánticos auto dark/light) |
| `lib/theme/jala_theme.dart` | Barrel file que exporta todo el tema |
| `lib/theme/util.dart` | `createTextTheme()` - fuente Plus Jakarta Sans via Google Fonts |

## Regla de oro

**NUNCA hardcodee colores hex en widgets.** Siempre usar las extensiones de contexto:

```dart
import '../../theme/jala_theme.dart';

// Dentro de build:
final colors = context.colors;  // ColorScheme
final styles = context.text;     // TextTheme
final brand = context.brand;     // JalaSemantic (colores del proyecto, auto dark/light)
```

## Forma recomendada (con extensiones)

```dart
import '../../theme/jala_theme.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.text;
    final brand = context.brand;

    return Container(
      color: colors.surface,
      child: Text(
        'Hola',
        style: styles.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
```

## JalaSemantic - Colores semánticos auto-adaptables

Estos colores cambian automáticamente entre modo claro y oscuro:

```dart
brand.greyDark        // Texto secundario
brand.greyLight       // Placeholder/hint
brand.greyBorder      // Bordes inactivos, drag handles
brand.surfaceLight    // Fondos claros
brand.divider         // Dividers, progress track
brand.accentSurface   // Fondo acento amber
brand.accentBlue      // Mapa/ubicación
brand.success         // Verde success
brand.successLight    // Fondo verde
brand.destructive     // Cancelar/eliminar
brand.destructiveLight // Fondo rojo
```

## JalaBrand - Colores de marca

```dart
abstract final class JalaBrand {
  static const Color amber      = Color(0xffff8f00);  // Acento primario
  static const Color amberDeep  = Color(0xff9a5200);  // Acento oscuro
  static const Color amberLight = Color(0xffffb066);  // Acento claro
  static const Color ink        = Color(0xff231d17);  // Texto principal / oscuro
  static const Color cream      = Color(0xfffbf7f2);  // Fondo claro
}
```

**Uso permitido de JalaBrand:** Solo para colores de marca specificos (amber, ink, cream). NO usar para colores genericos (grises, verdes, rojos).

## ColorScheme - Mapeo semantico

### Superficies y fondos

| Token | Uso | Ejemplo |
|-------|-----|---------|
| `scheme.surface` | Fondo principal de Scaffold | `Scaffold(backgroundColor: scheme.surface)` |
| `scheme.surfaceContainerLow` | Fondo de inputs, cards secundarios | `InputDecoration(fillColor: scheme.surfaceContainerLow)` |
| `scheme.surfaceContainerLowest` | Fondo de dropdowns, modales | `Container(color: scheme.surfaceContainerLowest)` |
| `scheme.surfaceContainer` | Fondo de cards elevadas | `Card(color: scheme.surfaceContainer)` |
| `scheme.surfaceContainerHigh` | Fondo de chips seleccionados | `Chip(backgroundColor: scheme.surfaceContainerHigh)` |
| `scheme.surfaceContainerHighest` | Fondo de badges activos | `Badge(backgroundColor: scheme.surfaceContainerHighest)` |

### Texto

| Token | Uso | Ejemplo |
|-------|-----|---------|
| `scheme.onSurface` | Texto principal, titulos | `Text('Hola', style: TextStyle(color: scheme.onSurface))` |
| `scheme.onSurfaceVariant` | Texto secundario, subtitulos, hints | `Text('Subtitulo', style: TextStyle(color: scheme.onSurfaceVariant))` |
| `scheme.onPrimary` | Texto sobre botones primarios | `FilledButton(child: Text('OK', style: TextStyle(color: scheme.onPrimary)))` |
| `scheme.onInverseSurface` | Texto sobre SnackBar | `SnackBar(content: Text('...', style: TextStyle(color: scheme.onInverseSurface)))` |

### Bordes y lineas

| Token | Uso | Ejemplo |
|-------|-----|---------|
| `scheme.outline` | Bordes de inputs, separadores | `Border.all(color: scheme.outline)` |
| `scheme.outlineVariant` | Bordes sutiles, drag handles, divider | `Container(decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant)))` |

### Acento y marca

| Token | Uso | Ejemplo |
|-------|-----|---------|
| `scheme.primary` | Color primario (ink en light) | `Icon(color: scheme.primary)` |
| `scheme.secondary` | Color secundario (amberDeep en light) | `Badge(backgroundColor: scheme.secondary)` |
| `scheme.inversePrimary` | Acento sobre superficies oscuras | `Color(amberLight)` |

### Semantico (error, success)

| Token | Uso | Ejemplo |
|-------|-----|---------|
| `scheme.error` | Errores,-destructivo, cancelado | `TextStyle(color: scheme.error)` |
| `scheme.errorContainer` | Fondo de errores | `Container(color: scheme.errorContainer)` |
| `scheme.onError` | Texto sobre error | `TextStyle(color: scheme.onError)` |

### Sombras e inverso

| Token | Uso | Ejemplo |
|-------|-----|---------|
| `scheme.inverseSurface` | Fondo de SnackBar | `SnackBar(backgroundColor: scheme.inverseSurface)` |
| `scheme.shadow` | Sombras | `BoxShadow(color: scheme.shadow.withValues(alpha: 0.1))` |

## Colores semanticos del proyecto (en JalaBrand o hardcoded)

Estos colores NO estan en `ColorScheme` estandar de Flutter. Agregar a `JalaBrand` o usar directamente:

### Texto secundario

| Color | Hex | Uso | Donde se usa |
|-------|-----|-----|--------------|
| `JalaBrand.greyDark` | `#6B6661` | Texto secundario, subtitulos | 7 archivos |
| `JalaBrand.greyLight` | `#B6B3B1` | Placeholder/hint text | 2 archivos |
| `JalaBrand.greyBorder` | `#D1D1D1` | Drag handles, bordes inactivos | 4 archivos |

### Superficies

| Color | Hex | Uso | Donde se usa |
|-------|-----|-----|--------------|
| `JalaBrand.surfaceLight` | `#F6F6F6` | Fondos claros, search bars | 5 archivos |
| `JalaBrand.divider` | `#ECECEC` | Dividers, progress track, bordes | 3 archivos |
| `JalaBrand.accentSurface` | `#FFF1E0` | Fondos de acento amber (iconos, tarjeta de tarifa) | 3 archivos |

### Semantico

| Color | Hex | Uso | Donde se usa |
|-------|-----|-----|--------------|
| `JalaBrand.success` | `#1E8E5A` | Completado, verificado | 2 archivos |
| `JalaBrand.successLight` | `#E6F4EA` | Fondo de completado | 1 archivo |
| `JalaBrand.destructive` | `#D84315` | Cancelar, eliminar, logout | 3 archivos |
| `JalaBrand.destructiveLight` | `#FCEAE6` | Fondo de cancelado/error | 1 archivo |
| `JalaBrand.accentBlue` | `#005B9F` | Mapa, ubicacion | 2 archivos |

## Como acceder a los colores

### En un StatelessWidget/ConsumerWidget

```dart
@override
Widget build(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;

  return Container(
    color: scheme.surface,
    child: Text(
      'Hola',
      style: text.bodyMedium?.copyWith(color: scheme.onSurface),
    ),
  );
}
```

### En un ConsumerStatefulWidget

```dart
@override
Widget build(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final text = Theme.of(context).textTheme;
  // ... usar scheme y text
}
```

### Para colores de JalaBrand

```dart
import '../../../../theme/theme.dart';

// Dentro de build:
Container(color: JalaBrand.amber)

// NO hardcodear:
Container(color: Color(0xffff8f00))  // MAL - duplica el valor
```

## Tipografia

La fuente global es **Plus Jakarta Sans** (configurada en `util.dart`).

### Estilos de texto del tema

| Estilo | Uso | Ejemplo |
|--------|-----|---------|
| `headlineMedium` | Titulos de pantalla | `Text('Jala', style: text.headlineMedium)` |
| `headlineSmall` | Subtitulos importantes | `Text('Tu viaje', style: text.headlineSmall)` |
| `titleLarge` | Titulos de seccion | `Text('Direccion', style: text.titleLarge)` |
| `titleMedium` | Titulos de card | `Text('Resumen', style: text.titleMedium)` |
| `bodyLarge` | Texto principal | `Text('Descripcion', style: text.bodyLarge)` |
| `bodyMedium` | Texto secundario | `Text('Detalle', style: text.bodyMedium)` |
| `bodySmall` | Texto auxiliar | `Text('Hint', style: text.bodySmall)` |
| `labelLarge` | Botones, chips | `Text('Confirmar', style: text.labelLarge)` |
| `labelMedium` | Labels de inputs | `Text('Correo', style: text.labelMedium)` |
| `labelSmall` | Badges, captions | `Text('NEW', style: text.labelSmall)` |

### Modificadores comunes

```dart
// Texto bold
text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)

// Texto con color especifico
text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)

// Texto con letter spacing
text.titleLarge?.copyWith(letterSpacing: -0.5)
```

## Temas de componentes

El `MaterialTheme` ya configura automáticamente:

| Componente | Tema configurado |
|------------|-----------------|
| `InputDecorationTheme` | Bordes redondeados 12dp, fondo `surfaceContainerLow`, focus amber |
| `FilledButtonTheme` | Altura 54dp, esquinas 14dp, font semi-bold |
| `OutlinedButtonTheme` | Altura 52dp, esquinas 14dp, borde `outlineVariant` |
| `TextButtonTheme` | Color acento `amberDeep`/`amberLight` |
| `CardTheme` | Sin elevation, esquinas 20dp, borde `outlineVariant` |
| `AppBarTheme` | Fondo surface, sin elevation, font titleLarge |
| `SnackBarTheme` | Floating, fondo `inverseSurface`, esquinas 12dp |
| `DividerTheme` | Color `outlineVariant`, thickness 1 |
| `ScaffoldBackgroundColor` | `scheme.surface` |

### Usa los widgets nativos cuando sea posible

```dart
// BIEN - usa el tema automaticamente
FilledButton(onPressed: () {}, child: Text('OK'))
OutlinedButton(onPressed: () {}, child: Text('Cancelar'))
Card(child: Padding(...))
Divider()
SnackBar(content: Text('...'))

// MAL - no aprovecha el tema
Container(
  decoration: BoxDecoration(
    color: Color(0xFFFF8F00),  // hardcodeado
    borderRadius: BorderRadius.circular(14),
  ),
  child: Text('OK'),
)
```

## Paleta de colores completa (para referencia)

```
JalaBrand:
  amber:      #FF8F00  (acento primario)
  amberDeep:  #9A5200  (acento oscuro)
  amberLight: #FFB066  (acento claro)
  ink:        #231D17  (texto/oscuro)
  cream:      #FBF7F2  (fondo claro)

Text:
  #1A1410  → scheme.onSurface (texto principal)
  #6B6661  → JalaBrand.greyDark (texto secundario)
  #B6B3B1  → JalaBrand.greyLight (placeholder)
  #C4C4C4  → scheme.outline (iconos trailing)

Superficies:
  #FFFFFF  → scheme.surfaceContainerLowest
  #F6F6F6  → JalaBrand.surfaceLight
  #F0F0F0  → scheme.surfaceContainerLow
  #ECECEC  → JalaBrand.divider
  #D1D1D1  → JalaBrand.greyBorder
  #FFF1E0  → JalaBrand.accentSurface
  #FBF7F2  → scheme.surface (cream)

Semantico:
  #1E8E5A  → JalaBrand.success
  #E6F4EA  → JalaBrand.successLight
  #D84315  → JalaBrand.destructive
  #FCEAE6  → JalaBrand.destructiveLight
  #005B9F  → JalaBrand.accentBlue
  #FFB300  → JalaBrand.amberDeep (gradient end)
```

## Checklist para nueva feature

Antes de agregar colores a un widget:

- [ ] Obtener `scheme` y `text` con `Theme.of(context)`
- [ ] Usar `scheme.onSurface` para texto principal
- [ ] Usar `scheme.onSurfaceVariant` para texto secundario
- [ ] Usar `scheme.surface` / `scheme.surfaceContainerLow` para fondos
- [ ] Usar `scheme.outlineVariant` para bordes
- [ ] Usar `scheme.error` para errores/destructivo
- [ ] Usar `JalaBrand.amber` solo para acento de marca
- [ ] Usar `JalaBrand.success`/`destructive` para semantico del proyecto
- [ ] NO hay `Color(0xFF...)` en el widget
- [ ] Los botones usan `FilledButton`/`OutlinedButton`/`TextButton` nativos
- [ ] Los cards usan `Card` nativo (ya tiene tema configurado)

## Comandos de verificacion

```bash
flutter analyze       # detecta colores no usados, warnings
```
