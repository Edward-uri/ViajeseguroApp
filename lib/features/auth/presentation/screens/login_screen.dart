import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/logo_badge.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/mock_location_detector.dart';
import '../../domain/services/usb_debug_detector.dart';
import '../provider/login_viewmodel.dart';


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>(
      create: (ctx) => LoginViewModel(
        ctx.read<AuthRepository>(),
        ctx.read<MockLocationDetector>(),
        ctx.read<UsbDebugDetector>(),
      ),
      child: const _LoginView(),
    );
  }
}


class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> with WidgetsBindingObserver {
  bool _closeScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LoginViewModel>().checkSecurity();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<LoginViewModel>().checkSecurity();
    }
  }

  void _scheduleAppClose() {
    if (_closeScheduled) return;
    _closeScheduled = true;
    // Se cierra en 5 segundos según requerimiento
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        SystemNavigator.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    if (vm.checkingSecurity) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Bloqueo por depuración USB activo (ADB)
    if (vm.usbDebugDetected) {
      _scheduleAppClose();
      return const _UsbDebugBlock();
    }

    if (vm.mockLocationDetected) {
      _scheduleAppClose();
      return const _MockLocationBlock();
    }

    return _LoginForm(onSubmit: _onSubmit);
  }

  Future<void> _onSubmit(BuildContext context) async {
    final vm = context.read<LoginViewModel>();
    final ok = await vm.submit();
    if (ok && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.profile,
        (route) => false,
      );
    }
  }
}

class _UsbDebugBlock extends StatelessWidget {
  const _UsbDebugBlock();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.adb_outlined,
                    size: 52,
                    color: scheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seguridad Comprometida',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Se ha detectado la depuración USB activa. Por políticas de seguridad, '
                    'debes desactivar esta opción en los ajustes de desarrollador. '
                    'La aplicación se cerrará en 5 segundos.',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => SystemNavigator.pop(),
                    icon: const Icon(Icons.exit_to_app_outlined),
                    label: const Text('Salir'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MockLocationBlock extends StatelessWidget {
  const _MockLocationBlock();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 52,
                    color: scheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ubicación simulada detectada',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Desactiva el Fake GPS o elimina la app de ubicación '
                    'simulada. La aplicación se cerrará en 5 segundos.',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => SystemNavigator.pop(),
                    icon: const Icon(Icons.exit_to_app_outlined),
                    label: const Text('Salir'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.onSubmit});

  final Future<void> Function(BuildContext context) onSubmit;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Center(child: LogoBadge(size: 112)),
                  const SizedBox(height: 24),
                  Text(
                    'Jala',
                    textAlign: TextAlign.center,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jalate con un mototaxi',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    enabled: !vm.isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: vm.setIdentifier,
                    decoration: const InputDecoration(
                      labelText: 'Usuario o correo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    enabled: !vm.isLoading,
                    obscureText: vm.obscurePassword,
                    textInputAction: TextInputAction.done,
                    onChanged: vm.setPassword,
                    onSubmitted: (_) => onSubmit(context),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: vm.togglePasswordVisibility,
                        icon: Icon(
                          vm.obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(message: vm.errorMessage!),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: vm.canSubmit ? () => onSubmit(context) : null,
                    child: vm.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: vm.isLoading
                        ? null
                        : () => Navigator.of(context)
                            .pushNamed(AppRoutes.register),
                    child: const Text('¿No tenés cuenta? Crear una'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: text.bodySmall?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
