import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes/app_routes.dart';
import '../../domain/entities/municipio.dart';
import '../provider/register_viewmodel.dart';
import 'register_widgets.dart';

class FormAdditionalStep extends ConsumerStatefulWidget {
  const FormAdditionalStep({super.key, required this.vm, required this.state});

  final RegisterViewModel vm;
  final RegisterViewModelState state;

  @override
  ConsumerState<FormAdditionalStep> createState() => _FormAdditionalStepState();
}

class _FormAdditionalStepState extends ConsumerState<FormAdditionalStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.vm.loadMunicipios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Información adicional',
          style: text.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Necesitamos algunos datos más',
          style: text.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Escribe tu numero de celular',
          enabled: !widget.state.isLoading,
          keyboardType: TextInputType.phone,
          hintText: 'Escribe tu numero de celular',
          maxLength: 12,
          onChanged: widget.vm.setTelefono,
        ),
        const SizedBox(height: 16),
        SexoDropdown(
          enabled: !widget.state.isLoading,
        ),
        const SizedBox(height: 16),
        FechaNacimientoField(
          enabled: !widget.state.isLoading,
        ),
        const SizedBox(height: 16),
        _MunicipioDropdown(
          enabled: !widget.state.isLoading,
          municipios: widget.state.municipios,
          loading: widget.state.municipiosLoading,
          loaded: widget.state.municipiosLoaded,
        ),
        const SizedBox(height: 24),
        Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        const SizedBox(height: 24),
        LabeledTextField(
          label: 'Contrasena',
          enabled: !widget.state.isLoading,
          obscureText: true,
          hintText: 'Minimo 8 caracteres, una mayuscula, un numero',
          onChanged: widget.vm.setContrasena,
        ),
        const SizedBox(height: 8),
        _PasswordRequirements(vm: widget.vm),
        const SizedBox(height: 16),
        LabeledTextField(
          label: 'Confirmar contrasena',
          enabled: !widget.state.isLoading,
          obscureText: true,
          hintText: 'Repite tu contrasena',
          errorText: widget.vm.confirmarContrasena.isNotEmpty && !widget.vm.passwordsMatch
              ? 'Las contrasenas no coinciden'
              : null,
          onChanged: widget.vm.setConfirmarContrasena,
        ),
        if (widget.state.errorMessage != null) ...[
          const SizedBox(height: 12),
          ErrorBanner(
            message: widget.state.errorMessage!,
            onDismiss: widget.vm.clearError,
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: widget.state.canSubmit ? () => _onSubmit(context, ref) : null,
          child: widget.state.isLoading
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onPrimary,
                  ),
                )
              : const Text('Crear cuenta'),
        ),
      ],
    );
  }

  Future<void> _onSubmit(BuildContext context, WidgetRef ref) async {
    final ok = await widget.vm.completeRegistration();
    if (ok && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }
}

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({required this.vm});

  final RegisterViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.contrasena.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequirementRow(
          label: 'Minimo 8 caracteres',
          met: vm.passwordHasMinLength,
        ),
        _RequirementRow(
          label: 'Una mayuscula (A-Z)',
          met: vm.passwordHasUpperCase,
        ),
        _RequirementRow(
          label: 'Una minuscula (a-z)',
          met: vm.passwordHasLowerCase,
        ),
        _RequirementRow(
          label: 'Un numero (0-9)',
          met: vm.passwordHasDigit,
        ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? const Color(0xFF1E8E5A) : const Color(0xFF6B6661);
    final icon = met ? Icons.check_circle : Icons.radio_button_unchecked;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MunicipioDropdown extends ConsumerStatefulWidget {
  const _MunicipioDropdown({
    required this.enabled,
    required this.municipios,
    required this.loading,
    required this.loaded,
  });

  final bool enabled;
  final List<Municipio> municipios;
  final bool loading;
  final bool loaded;

  @override
  ConsumerState<_MunicipioDropdown> createState() => _MunicipioDropdownState();
}

class _MunicipioDropdownState extends ConsumerState<_MunicipioDropdown> with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _searchQuery = '';
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<Municipio> get _filteredMunicipios {
    if (_searchQuery.isEmpty) return widget.municipios;
    final query = _searchQuery.toLowerCase();
    return widget.municipios
        .where((m) =>
            m.nombre.toLowerCase().contains(query) ||
            m.estado.toLowerCase().contains(query))
        .toList();
  }

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
        if (!widget.loaded) {
          ref.read(registerViewModelProvider.notifier).loadMunicipios();
        }
      } else {
        _animationController.reverse();
      }
    });
  }

  void _selectMunicipio(Municipio municipio) {
    setState(() {
      _controller.text = municipio.displayName;
      _isOpen = false;
      _searchQuery = '';
      _animationController.reverse();
    });
    ref.read(registerViewModelProvider.notifier).setIdMunicipio(municipio.idMunicipio.toString());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Municipio',
          style: text.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          enabled: widget.enabled,
          readOnly: true,
          controller: _controller,
          onTap: widget.enabled ? _toggleDropdown : null,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Municipio, Estado',
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
            constraints: const BoxConstraints(maxHeight: 200),
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
            child: widget.loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )),
                  )
                : _filteredMunicipios.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No se encontraron municipios',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _filteredMunicipios.length,
                        itemBuilder: (context, index) {
                          final municipio = _filteredMunicipios[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              '${municipio.nombre}, ${municipio.estado}',
                              style: text.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () => _selectMunicipio(municipio),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }
}
