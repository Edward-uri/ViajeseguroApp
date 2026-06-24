import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/jala_alert_banner.dart';
import '../provider/register_viewmodel.dart';

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.enabled,
    required this.onChanged,
    this.keyboardType,
    this.hintText,
    this.maxLength,
    this.obscureText = false,
    this.errorText,
  });

  final String label;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final String? hintText;
  final int? maxLength;
  final bool obscureText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          enabled: enabled,
          keyboardType: keyboardType,
          maxLength: maxLength,
          obscureText: obscureText,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hintText ?? '',
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            counterText: maxLength != null ? '' : null,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

class SexoDropdown extends ConsumerStatefulWidget {
  const SexoDropdown({
    super.key,
    required this.enabled,
  });

  final bool enabled;

  @override
  ConsumerState<SexoDropdown> createState() => _SexoDropdownState();
}

class _SexoDropdownState extends ConsumerState<SexoDropdown> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  String _selectedValue = '';
  late AnimationController _animationController;
  late Animation<double> _animation;

  static const List<_SexoOption> _options = [
    _SexoOption(value: '1', label: 'Masculino'),
    _SexoOption(value: '2', label: 'Femenino'),
    _SexoOption(value: '3', label: 'Otro'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _displayText {
    if (_selectedValue.isEmpty) return 'Selecciona tu sexo';
    return _options.firstWhere((o) => o.value == _selectedValue).label;
  }

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _selectOption(String value) {
    setState(() {
      _selectedValue = value;
      _isOpen = false;
      _animationController.reverse();
    });
    ref.read(registerViewModelProvider.notifier).setIdSexo(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sexo',
          style: text.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          enabled: widget.enabled,
          readOnly: true,
          onTap: widget.enabled ? _toggleDropdown : null,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Selecciona tu sexo',
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            suffixIcon: AnimatedRotation(
              turns: _isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.arrow_drop_down,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          controller: TextEditingController(text: _displayText),
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            if (_animation.value == 0) return const SizedBox.shrink();
            return Opacity(
              opacity: _animation.value,
              child: Transform.translate(
                offset: Offset(0, -10 * (1 - _animation.value)),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _options.length,
              itemBuilder: (context, index) {
                final option = _options[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    option.label,
                    style: text.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => _selectOption(option.value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SexoOption {
  const _SexoOption({required this.value, required this.label});
  final String value;
  final String label;
}

class FechaNacimientoField extends ConsumerStatefulWidget {
  const FechaNacimientoField({
    super.key,
    required this.enabled,
  });

  final bool enabled;

  @override
  ConsumerState<FechaNacimientoField> createState() => _FechaNacimientoFieldState();
}

class _FechaNacimientoFieldState extends ConsumerState<FechaNacimientoField> {
  String _selectedDate = '';

  void _selectDate(String formatted) {
    setState(() => _selectedDate = formatted);
    ref.read(registerViewModelProvider.notifier).setFechaNacimiento(formatted);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fecha de nacimiento',
          style: text.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          enabled: widget.enabled,
          readOnly: true,
          controller: TextEditingController(text: _selectedDate),
          onTap: widget.enabled
              ? () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1940),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    final formatted = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    _selectDate(formatted);
                  }
                }
              : null,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            suffixIcon: Icon(Icons.calendar_today, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return JalaAlertBanner(
      message: message,
      type: JalaAlertType.error,
      onDismiss: onDismiss,
    );
  }
}
