---
name: jala-alerts
description: Crea y aplica alertas y dialogos estilo Jala en Flutter. Usa cuando se necesiten dialogos de confirmacion, alertas que aparecen con boton de cancelar, snackbars o notificaciones in-app. Proporciona el widget JalaDialog y JalaConfirmDialog con el look-and-feel de la app (Material 3, JalaBrand.amber, esquinas redondeadas, iconos en circulo). Mantiene consistencia visual en todas las alertas de la app.
---

# Alertas y Dialogos - ViajeseguroApp

## Widget principal: JalaDialog

Ubicacion: `lib/shared/widgets/jala_dialog.dart`

Dialogo modal con estilo Jala: icono en circulo, titulo, mensaje, botones
Cancelar/Confirmar. Usa `showDialog` con `JalaDialog` o helpers.

## Cuando usar cada tipo

| Tipo | Widget | Uso |
|------|--------|-----|
| Confirmacion (Cancelar/OK) | `JalaConfirmDialog` | Acciones destructivas: cerrar sesion, cancelar viaje, eliminar cuenta |
| Info | `JalaAlertDialog` | Avisos no destructivos |
| SnackBar | `ScaffoldMessenger` | Feedback temporal tras una accion |

## Helpers estaticos

```dart
// Confirmacion con Cancelar / Confirmar
final ok = await JalaDialog.confirm(
  context,
  title: 'Cerrar sesion',
  message: '¿Seguro que quieres cerrar sesion?',
  confirmText: 'Cerrar sesion',
  cancelText: 'Cancelar',
  type: JalaAlertType.warning,
);

// Aviso simple con un solo boton
await JalaDialog.alert(
  context,
  title: 'Viaje cancelado',
  message: 'Tu viaje ha sido cancelado.',
  type: JalaAlertType.info,
);
```

## Reglas de estilo

- **Icono**: en circulo de 56dp con color segun tipo (error/warning/info/success)
- **Color de acento**: `JalaBrand.amber` por defecto, `colorScheme.error` para destructivo
- **Esquinas**: `Radius.circular(24)` en el dialogo
- **Boton primario**: `FilledButton` con color de acento
- **Boton secundario**: `OutlinedButton` o `TextButton`
- **Titulo**: `headlineSmall` con `FontWeight.w700`
- **Mensaje**: `bodyMedium` con `colorScheme.onSurfaceVariant`
- **Padding**: 24dp horizontal, 24dp vertical
- **Cancelar** siempre a la izquierda, **Confirmar** a la derecha

## Integracion con ViewModels

Los ViewModels NO muestran dialogos directamente. Retornan bool/results
y la Screen decide si mostrar un `JalaDialog`:

```dart
// En la Screen
Future<void> _logout(BuildContext context, WidgetRef ref) async {
  final ok = await JalaDialog.confirm(
    context,
    title: 'Cerrar sesion',
    message: '¿Seguro que quieres cerrar sesion?',
    confirmText: 'Cerrar sesion',
    type: JalaAlertType.warning,
  );
  if (!ok || !context.mounted) return;
  await ref.read(profileViewModelProvider.notifier).logout();
  if (context.mounted) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login, (route) => false,
    );
  }
}
```

## Tipos de alerta

```dart
enum JalaAlertType { error, success, warning, info }
```

- **error**: rojo (`colorScheme.error`), icono `Icons.error_rounded`
- **success**: verde, icono `Icons.check_circle_rounded`
- **warning**: ambar (`JalaBrand.amber`), icono `Icons.warning_amber_rounded`
- **info**: primario, icono `Icons.info_rounded`
