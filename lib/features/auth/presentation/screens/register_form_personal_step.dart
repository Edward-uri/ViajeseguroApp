import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/widgets.dart';
import '../provider/register_viewmodel.dart';
import 'register_widgets.dart';

class FormPersonalStep extends ConsumerWidget {
  const FormPersonalStep({super.key, required this.vm, required this.state});

  final RegisterViewModel vm;
  final RegisterViewModelState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: Text(
            'Datos personales',
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 6),
        FadeSlideIn(
          delay: const Duration(milliseconds: 180),
          child: Text(
            'Cuéntanos sobre ti',
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 260),
          child: LabeledTextField(
            label: 'Nombre',
            enabled: !state.isLoading,
            onChanged: vm.setNombre,
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 340),
          child: LabeledTextField(
            label: 'Apellido paterno',
            enabled: !state.isLoading,
            onChanged: vm.setApellidoPaterno,
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 420),
          child: LabeledTextField(
            label: 'Apellido materno',
            enabled: !state.isLoading,
            onChanged: vm.setApellidoMaterno,
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          FadeSlideIn(
            child: ErrorBanner(
              message: state.errorMessage!,
              onDismiss: vm.clearError,
            ),
          ),
        ],
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 500),
          child: FilledButton(
            onPressed: state.canSubmit ? () => vm.goToAdditionalForm() : null,
            child: state.isLoading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const Text('Continuar'),
          ),
        ),
      ],
    );
  }
}
