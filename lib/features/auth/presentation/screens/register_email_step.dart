import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/widgets.dart';
import '../provider/register_viewmodel.dart';
import 'register_widgets.dart';

class EmailStep extends ConsumerWidget {
  const EmailStep({super.key, required this.vm, required this.state});

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
            'Comencemos',
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
            'Coloca tu correo electrónico y te enviaremos un código',
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 260),
          child: Text(
            'Correo electrónico',
            style: text.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 6),
        FadeSlideIn(
          delay: const Duration(milliseconds: 340),
          child: TextField(
            enabled: !state.isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: vm.setCorreo,
            decoration: InputDecoration(
              hintText: 'ejemplo@correo.com',
              prefixIcon: Icon(Icons.alternate_email, color: scheme.onSurfaceVariant),
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface,
            ),
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
          delay: const Duration(milliseconds: 420),
          child: FilledButton(
            onPressed: state.canSubmit ? () => vm.sendOtp() : null,
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
