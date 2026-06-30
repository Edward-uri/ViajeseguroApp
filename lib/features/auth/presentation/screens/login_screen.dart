import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/widgets/bubble_loader.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/widgets.dart';
import '../provider/login_viewmodel.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _LoginView();
  }
}

class _LoginView extends ConsumerStatefulWidget {
  const _LoginView();

  @override
  ConsumerState<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<_LoginView> with WidgetsBindingObserver {
  bool _closeScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(loginViewModelProvider.notifier).checkSecurity();
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
      final vm = ref.read(loginViewModelProvider);
      if (!vm.checkingSecurity && !vm.isSecurityCompromised) {
        ref.read(loginViewModelProvider.notifier).checkSecurity();
      }
    }
  }

  void _scheduleAppClose() {
    if (_closeScheduled) return;
    _closeScheduled = true;
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        SystemNavigator.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(loginViewModelProvider);

    if (vm.checkingSecurity) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'lib/shared/icons/Mototaxi Línea.svg',
                width: 120,
                height: 90,
              ),
              const SizedBox(height: 24),
              const BubbleLoader(),
            ],
          ),
        ),
      );
    }

    if (vm.usbDebugDetected) {
      _scheduleAppClose();
      return const _UsbDebugBlock();
    }

    if (vm.mockLocationDetected) {
      _scheduleAppClose();
      return const _MockLocationBlock();
    }

    return _LoginContent(onSubmit: _onSubmit);
  }

  Future<void> _onSubmit(BuildContext context) async {
    final vm = ref.read(loginViewModelProvider.notifier);
    final ok = await vm.login();
    if (ok && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.passengerHome,
        (route) => false,
      );
    }
  }
}

class _LoginContent extends ConsumerStatefulWidget {
  const _LoginContent({required this.onSubmit});

  final Future<void> Function(BuildContext context) onSubmit;

  @override
  ConsumerState<_LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends ConsumerState<_LoginContent> {
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(loginViewModelProvider);
    final notifier = ref.read(loginViewModelProvider.notifier);
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
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: Center(
                      child: SvgPicture.asset(
                        'lib/shared/icons/Mototaxi Línea.svg',
                        width: 160,
                        height: 120,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Jala',
                      textAlign: TextAlign.center,
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 280),
                    child: Text(
                      'Jalate con un mototaxi',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 360),
                    child: TextField(
                      enabled: !vm.isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: notifier.setCorreo,
                      decoration: const InputDecoration(
                        labelText: 'Correo electronico',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 440),
                    child: TextField(
                      enabled: !vm.isLoading,
                      obscureText: !_passwordVisible,
                      textInputAction: TextInputAction.done,
                      onChanged: notifier.setContrasena,
                      onSubmitted: (_) => widget.onSubmit(context),
                      decoration: InputDecoration(
                        labelText: 'Contrasena',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() => _passwordVisible = !_passwordVisible);
                          },
                        ),
                      ),
                    ),
                  ),
                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      child: JalaAlertBanner(
                        message: vm.errorMessage!,
                        onDismiss: () =>
                            ref.read(loginViewModelProvider.notifier).clearError(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 520),
                    child: FilledButton(
                      onPressed: vm.canSubmit ? () => widget.onSubmit(context) : null,
                      child: vm.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: scheme.onPrimary,
                              ),
                            )
                          : const Text('Iniciar sesion'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 600),
                    child: TextButton(
                      onPressed: vm.isLoading
                          ? null
                          : () {
                              ref.read(loginViewModelProvider.notifier).clearError();
                              Navigator.of(context).pushNamed(AppRoutes.register);
                            },
                      child: const Text('¿No tienes cuenta? Crear una'),
                    ),
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
                  FadeSlideIn(
                    child: Icon(
                      Icons.adb_outlined,
                      size: 52,
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: Text(
                      'Seguridad Comprometida',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'Se ha detectado la depuracion USB activa. Por politicas de seguridad, '
                      'debes desactivar esta opcion en los ajustes de desarrollador. '
                      'La aplicacion se cerrara en 5 segundos.',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 450),
                    child: FilledButton.icon(
                      onPressed: () => SystemNavigator.pop(),
                      icon: const Icon(Icons.exit_to_app_outlined),
                      label: const Text('Salir'),
                    ),
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
                  FadeSlideIn(
                    child: Icon(
                      Icons.location_off_outlined,
                      size: 52,
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: Text(
                      'Ubicacion simulada detectada',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'Desactiva el Fake GPS o elimina la app de ubicacion '
                      'simulada. La aplicacion se cerrara en 5 segundos.',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 450),
                    child: FilledButton.icon(
                      onPressed: () => SystemNavigator.pop(),
                      icon: const Icon(Icons.exit_to_app_outlined),
                      label: const Text('Salir'),
                    ),
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
