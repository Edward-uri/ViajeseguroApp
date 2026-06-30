import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/widgets.dart';
import '../provider/register_viewmodel.dart';
import 'register_widgets.dart';

class OtpStep extends ConsumerStatefulWidget {
  const OtpStep({super.key, required this.vm, required this.state, required this.correo});

  final RegisterViewModel vm;
  final RegisterViewModelState state;
  final String correo;

  @override
  ConsumerState<OtpStep> createState() => OtpStepState();
}

class OtpStepState extends ConsumerState<OtpStep> {
  final List<FocusNode> _focusNodes = [
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
    FocusNode(),
  ];
  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    widget.vm.setCodigo(code);

    // Ocultar teclado cuando se completa el código
    if (code.length == 6) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: Text(
            'Código',
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
            'Revisa tu correo electrónico e ingresa el código de 6 dígitos',
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FadeSlideIn(
          delay: const Duration(milliseconds: 260),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Enviado a '),
                TextSpan(
                  text: widget.correo,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 4),
        FadeSlideIn(
          delay: const Duration(milliseconds: 300),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.vm.goBackToEmail,
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(
                'Cambiar correo',
                style: text.labelMedium,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 380),
          child: Row(
            children: List.generate(6, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 6,
                    right: index == 5 ? 0 : 6,
                  ),
                  child: TextField(
                    focusNode: _focusNodes[index],
                    controller: _controllers[index],
                    enabled: !widget.state.isLoading,
                    keyboardType: TextInputType.number,
                    textInputAction: index < 5
                        ? TextInputAction.next
                        : TextInputAction.done,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    onChanged: (value) => _onChanged(index, value),
                    onSubmitted: index == 5 ? (_) => widget.vm.verifyOtp() : null,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (widget.state.errorMessage != null) ...[
          const SizedBox(height: 12),
          FadeSlideIn(
            child: ErrorBanner(
              message: widget.state.errorMessage!,
              onDismiss: widget.vm.clearError,
            ),
          ),
        ],
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 460),
          child: FilledButton(
            onPressed: widget.state.canSubmit ? () => widget.vm.verifyOtp() : null,
            child: widget.state.isLoading
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
