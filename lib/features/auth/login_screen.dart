import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mock_location_guard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with WidgetsBindingObserver {
  static const String demoUser = 'demo';
  static const String demoPassword = '12345';

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mockLocationGuard = MockLocationGuard();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _checkingMockLocation = true;
  bool _mockLocationEnabled = false;
  bool _mockWarningShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkMockLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkMockLocation();
    }
  }

  Future<void> _checkMockLocation() async {
    if (mounted) {
      setState(() => _checkingMockLocation = true);
    }
    final enabled = await _mockLocationGuard.isMockLocationEnabled();
    if (!mounted) return;
    setState(() {
      _mockLocationEnabled = enabled;
      _checkingMockLocation = false;
    });
    if (enabled) {
      _showMockLocationWarning();
    }
  }

  Future<void> _showMockLocationWarning() async {
    if (_mockWarningShown || !mounted) return;
    _mockWarningShown = true;

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        SystemNavigator.pop();
      }
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ubicacion simulada detectada'),
        content: const Text(
          'Desactiva el Fake GPS o elimina la app de ubicacion simulada. La aplicacion se cerrara.',
        ),
        actions: [
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    setState(() => _loading = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _loading = false);

      final ok = _identifierController.text.trim() == demoUser &&
          _passwordController.text == demoPassword;

      final messenger = ScaffoldMessenger.of(context);
      final scheme = Theme.of(context).colorScheme;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Bienvenido, $demoUser' : 'Credenciales incorrectas',
          ),
          backgroundColor: ok ? scheme.primaryContainer : scheme.errorContainer,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (_checkingMockLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_mockLocationEnabled) {
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
                      'Ubicacion simulada detectada',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Desactiva el Fake GPS o elimina la app de ubicacion simulada. La aplicacion se cerrara.',
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
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.directions_bike_outlined,
                        size: 40,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ViajeSeguro',
                    textAlign: TextAlign.center,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Iniciá sesión para pedir tu moto-taxi',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Usuario o correo',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                    ],
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
