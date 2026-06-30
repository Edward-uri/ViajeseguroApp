import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../theme/jala_theme.dart';
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
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

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
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: Text(
            'Información adicional',
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
            'Necesitamos algunos datos más',
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 260),
          child: LabeledTextField(
            label: 'Numero de celular',
            enabled: !widget.state.isLoading,
            keyboardType: TextInputType.phone,
            hintText: '10 digitos',
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: widget.vm.setTelefono,
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 340),
          child: SexoDropdown(
            enabled: !widget.state.isLoading,
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 420),
          child: FechaNacimientoField(
            enabled: !widget.state.isLoading,
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 500),
          child: _MunicipioDropdown(
            enabled: !widget.state.isLoading,
            municipios: widget.state.municipios,
            loading: widget.state.municipiosLoading,
            loaded: widget.state.municipiosLoaded,
          ),
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 560),
          child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 620),
          child: LabeledTextField(
            label: 'Contrasena',
            enabled: !widget.state.isLoading,
            obscureText: !_passwordVisible,
            hintText: 'Minimo 8 caracteres, una mayuscula, un numero',
            onChanged: widget.vm.setContrasena,
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FadeSlideIn(
          delay: const Duration(milliseconds: 680),
          child: _PasswordRequirements(vm: widget.vm),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 740),
          child: LabeledTextField(
            label: 'Confirmar contrasena',
            enabled: !widget.state.isLoading,
            obscureText: !_confirmPasswordVisible,
            hintText: 'Repite tu contrasena',
            errorText: widget.vm.confirmarContrasena.isNotEmpty && !widget.vm.passwordsMatch
                ? 'Las contrasenas no coinciden'
                : null,
            onChanged: widget.vm.setConfirmarContrasena,
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
            ),
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
          delay: const Duration(milliseconds: 800),
          child: FilledButton(
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final requirements = [
      (label: 'Minimo 8 caracteres', met: vm.passwordHasMinLength),
      (label: 'Una mayuscula (A-Z)', met: vm.passwordHasUpperCase),
      (label: 'Una minuscula (a-z)', met: vm.passwordHasLowerCase),
      (label: 'Un numero (0-9)', met: vm.passwordHasDigit),
    ];

    final metCount = requirements.where((r) => r.met).length;
    final allMet = metCount == requirements.length;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      child: vm.contrasena.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        value: metCount / requirements.length,
                        strokeWidth: 2,
                        backgroundColor: scheme.outlineVariant.withValues(alpha: 0.3),
                        color: allMet ? context.brand.success : scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      allMet ? 'Contrasena segura' : '$metCount/${requirements.length} requisitos',
                      style: text.labelSmall?.copyWith(
                        color: allMet ? context.brand.success : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...requirements.map((r) => _RequirementRow(
                  label: r.label,
                  met: r.met,
                )),
                if (vm.confirmarContrasena.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _RequirementRow(
                    label: 'Las contrasenas coinciden',
                    met: vm.passwordsMatch,
                  ),
                ],
              ],
            ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? context.brand.success : context.brand.greyDark;
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
              color: scheme.surfaceContainerLow,
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
