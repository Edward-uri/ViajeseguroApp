import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../routes/app_routes.dart';
import '../../domain/repositories/auth_repository.dart';
import '../provider/register_viewmodel.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RegisterViewModel>(
      create: (ctx) => RegisterViewModel(ctx.read<AuthRepository>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tus datos',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    enabled: !vm.isLoading,
                    textInputAction: TextInputAction.next,
                    onChanged: vm.setNombre,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !vm.isLoading,
                    textInputAction: TextInputAction.next,
                    onChanged: vm.setApellidoPaterno,
                    decoration: const InputDecoration(
                      labelText: 'Apellido paterno',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !vm.isLoading,
                    textInputAction: TextInputAction.next,
                    onChanged: vm.setApellidoMaterno,
                    decoration: const InputDecoration(
                      labelText: 'Apellido materno (opcional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !vm.isLoading,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onChanged: vm.setTelefono,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cuenta',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    enabled: !vm.isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: vm.setCorreo,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !vm.isLoading,
                    textInputAction: TextInputAction.next,
                    onChanged: vm.setNombreUsuario,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario',
                      prefixIcon: Icon(Icons.person_outline),
                      helperText: 'Mínimo 3 caracteres',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: !vm.isLoading,
                    obscureText: vm.obscurePassword,
                    textInputAction: TextInputAction.done,
                    onChanged: vm.setPassword,
                    onSubmitted: (_) => _onSubmit(context),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      helperText: 'Mínimo 8 caracteres',
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
                    onPressed: vm.canSubmit ? () => _onSubmit(context) : null,
                    child: vm.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: scheme.onPrimary,
                            ),
                          )
                        : const Text('Crear cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit(BuildContext context) async {
    final vm = context.read<RegisterViewModel>();
    final ok = await vm.submit();
    if (ok && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.profile,
        (route) => false,
      );
    }
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
