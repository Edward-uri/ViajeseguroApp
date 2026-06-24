---
name: mobile-animations
description: Proporciona guías para implementar animaciones en Flutter siguiendo mejores prácticas móviles. Usa cuando se necesiten transiciones entre pantallas, animaciones de entrada/salida, microinteracciones, animaciones de carga, gestos animados o cualquier efecto visual animado en la app móvil. Incluye patrones para AnimatedContainer, Hero, AnimatedSwitcher, ImplicitAnimatedWidget y animaciones con Rive/Lottie.
---

# Animaciones Móviles en Flutter

## Principios de animación móvil

### Duraciones recomendadas

```dart
const Duration kDurationFast = Duration(milliseconds: 150);    // Microinteracciones
const Duration kDurationNormal = Duration(milliseconds: 250);  // Transiciones estándar
const Duration kDurationSlow = Duration(milliseconds: 400);    // Transiciones complejas
const Duration kDurationPage = Duration(milliseconds: 300);    // Navegación entre páginas
```

### Curvas de animación

```dart
// Entrada - elementos que aparecen
Curves.easeOut       // Rápido al inicio, lento al final
Curves.easeOutCubic  // Más pronunciado
Curves.easeOutQuart  // Muy pronunciado

// Salida - elementos que desaparecen
Curves.easeIn        // Lento al inicio, rápido al final
Curves.easeInCubic   // Más pronunciado

// Movimiento - elementos que se mueven
Curves.easeInOut     // Suave en ambos extremos
Curves.easeInOutCubic // Más pronunciado

// Rebote - elementos juguetones
Curves.elasticOut    // Rebote al final
Curves.bounceOut     // Rebote al final (más sutil)
```

## Animaciones implícitas

### AnimatedContainer

Para cambios de tamaño, color, padding, etc.:

```dart
AnimatedContainer(
  duration: Duration(milliseconds: 250),
  curve: Curves.easeOutCubic,
  width: _expanded ? 200 : 100,
  height: _expanded ? 200 : 100,
  decoration: BoxDecoration(
    color: _expanded ? Colors.amber : Colors.grey,
    borderRadius: BorderRadius.circular(_expanded ? 20 : 8),
  ),
)
```

### AnimatedOpacity

Para fade in/out:

```dart
AnimatedOpacity(
  opacity: _visible ? 1.0 : 0.0,
  duration: Duration(milliseconds: 200),
  child: Text('Hola'),
)
```

### AnimatedSwitcher

Para transicionar entre widgets:

```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 300),
  transitionBuilder: (child, animation) {
    return FadeTransition(opacity: animation, child: child);
  },
  child: _isLoading
      ? CircularProgressIndicator(key: ValueKey('loading'))
      : Text('Datos', key: ValueKey('data')),
)
```

### AnimatedPositioned

Para mover widgets dentro de Stack:

```dart
Stack(
  children: [
    AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: _expanded ? 100 : 200,
      left: 50,
      child: Container(...),
    ),
  ],
)
```

### AnimatedAlign

Para animar alineación:

```dart
AnimatedAlign(
  alignment: _expanded ? Alignment.topCenter : Alignment.center,
  duration: Duration(milliseconds: 300),
  curve: Curves.easeOutCubic,
  child: Container(...),
)
```

## Animaciones explícitas

### AnimationController básico

```dart
class _MiWidgetState extends State<MiWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(...),
      ),
    );
  }
}
```

### Animaciones secuenciales

```dart
Future<void> _runSequence() async {
  await _controller.forward();      // Primera animación
  await Future.delayed(Duration(milliseconds: 100));
  await _controller2.forward();     // Segunda animación
}
```

### Animaciones en paralelo

```dart
_controller.forward();
_controller2.forward();  // Ambas inician al mismo tiempo
```

## Transiciones de página

### PageRouteBuilder personalizado

```dart
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => NuevaPantalla(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: Duration(milliseconds: 250),
  ),
);
```

### Slide transition

```dart
PageRouteBuilder(
  pageBuilder: (context, animation, secondaryAnimation) => NuevaPantalla(),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    var begin = Offset(1.0, 0.0);
    var end = Offset.zero;
    var tween = Tween(begin: begin, end: end);
    var offsetAnimation = animation.drive(tween);
    
    return SlideTransition(position: offsetAnimation, child: child);
  },
)
```

### Hero transitions

Para elementos compartidos entre pantallas:

```dart
// Pantalla 1
Hero(
  tag: 'mi-imagen',
  child: Image.asset('logo.png'),
)

// Pantalla 2
Hero(
  tag: 'mi-imagen',
  child: Image.asset('logo.png'),
)
```

## Microinteracciones

### Botón con feedback

```dart
class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  const AnimatedButton({required this.onPressed, required this.text});

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: FilledButton(
          onPressed: () {}, // Deshabilitado porque usamos GestureDetector
          child: Text(widget.text),
        ),
      ),
    );
  }
}
```

### Shimmer loading

```dart
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;

  const ShimmerLoading({required this.width, required this.height});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 0.5, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}
```

## Animaciones de entrada

### Staggered animation (escalonada)

```dart
class StaggeredEntry extends StatefulWidget {
  final List<Widget> children;

  const StaggeredEntry({required this.children});

  @override
  State<StaggeredEntry> createState() => _StaggeredEntryState();
}

class _StaggeredEntryState extends State<StaggeredEntry>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.children.length, (index) {
        final delay = index * 0.1;
        final start = delay;
        final end = delay + 0.4;

        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end.clamp(0, 1), curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: widget.children[index],
          ),
        );
      }),
    );
  }
}
```

## Gestos animados

### Swipe to dismiss

```dart
class SwipeToDismiss extends StatefulWidget {
  final Widget child;
  final VoidCallback onDismissed;

  const SwipeToDismiss({required this.child, required this.onDismissed});

  @override
  State<SwipeToDismiss> createState() => _SwipeToDismissState();
}

class _SwipeToDismissState extends State<SwipeToDismiss>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dragAnimation;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _dragAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragOffset += details.delta.dx;
    _controller.value = (_dragOffset / 200).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() > 100) {
      widget.onDismissed();
    } else {
      _controller.reverse().then((_) {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dragAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_dragOffset, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: widget.child,
      ),
    );
  }
}
```

## Lottie y Rive

### Lottie animations

```dart
import 'package:lottie/lottie.dart';

Lottie.asset(
  'assets/animations/loading.json',
  width: 100,
  height: 100,
  repeat: true,
)
```

### Rive animations

```dart
import 'package:rive/rive.dart';

RiveAnimation.asset(
  'assets/animations/button.riv',
  animations: ['idle', 'pressed'],
  stateMachines: ['ButtonState'],
  onInit: (artboard) {
    // Configurar state machine
  },
)
```

## Performance

### Reglas de oro

1. **Usar `const`** cuando sea posible
2. **Evitar rebuilds innecesarios** con `AnimatedBuilder` o `Consumer`
3. **Usar `RepaintBoundary`** para aislar áreas animadas
4. **Limitar animaciones simultáneas** a 2-3 máximo
5. **Usar `TickerProviderStateMixin`** solo cuando sea necesario

### Ejemplo con RepaintBoundary

```dart
RepaintBoundary(
  child: AnimatedBuilder(
    animation: _animation,
    builder: (context, child) {
      return Transform.rotate(
        angle: _animation.value,
        child: child,
      );
    },
    child: Icon(Icons.refresh),
  ),
)
```

## Checklist de animaciones

- [ ] ¿La duración es apropiada (150-400ms)?
- [ ] ¿Usaste la curva correcta (easeOut para entrada)?
- [ ] ¿Dispose del AnimationController?
- [ ] ¿Usaste `const` en widgets estáticos?
- [ ] ¿Probaste en dispositivo real (no solo emulador)?
- [ ] ¿Las animaciones no bloquean la interacción?
- [ ] ¿Respetas la accesibilidad (reduce motion)?

## Accesibilidad

### Respetar preferencias del usuario

```dart
final reduceMotion = MediaQuery.of(context).disableAnimations;

if (reduceMotion) {
  return widget.child; // Sin animación
} else {
  return AnimatedWidget(...); // Con animación
}
```
