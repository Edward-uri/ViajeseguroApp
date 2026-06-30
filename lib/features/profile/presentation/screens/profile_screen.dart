import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/core_module.dart';
import '../../../../core/http/api_client.dart';
import '../../../../core/widgets/bubble_loader.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/domain/entities/user.dart';
import '../../../../shared/widgets/auth_image_provider.dart';
import '../../../../shared/widgets/fade_slide_in.dart';
import '../../../../shared/widgets/jala_alert_banner.dart';
import '../../../../theme/theme.dart';
import '../../../../theme/theme_extensions.dart';
import '../provider/profile_viewmodel.dart';

const Map<String, String> _allowedImageMimeByExt = <String, String>{
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileViewModelProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _ProfileView();
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(profileViewModelProvider);
    final scheme = Theme.of(context).colorScheme;

    if (vm.hasSessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      });
    }

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: vm.isLoading ? null : () => ref.read(profileViewModelProvider.notifier).loadProfile(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (vm.isLoading && vm.user == null) {
              return const Center(child: BubbleLoader());
            }
            final user = vm.user;
            if (user == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: scheme.error),
                      const SizedBox(height: 16),
                      Text(
                        vm.errorMessage ?? 'No se pudo cargar el perfil',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () => ref.read(profileViewModelProvider.notifier).loadProfile(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return _ProfileContent(user: user);
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  const _ProfileContent({required this.user});

  final User user;

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoPaternoCtrl;
  late TextEditingController _apellidoMaternoCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _correoCtrl;
  DateTime? _fechaNacimiento;
  int? _idSexo;
  bool _isEditing = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initControllers(widget.user);
      _initialized = true;
    }
  }

  @override
  void didUpdateWidget(covariant _ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      _initControllers(widget.user);
    }
  }

  void _initControllers(User user) {
    _nombreCtrl = TextEditingController(text: user.nombre ?? '');
    _apellidoPaternoCtrl = TextEditingController(text: user.apellidoPaterno ?? '');
    _apellidoMaternoCtrl = TextEditingController(text: user.apellidoMaterno ?? '');
    _telefonoCtrl = TextEditingController(text: user.telefono);
    _correoCtrl = TextEditingController(text: user.correoElectronico ?? '');
    _fechaNacimiento = user.fechaNacimiento;
    _idSexo = user.idSexo;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoPaternoCtrl.dispose();
    _apellidoMaternoCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(profileViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final user = widget.user;
    final apiClient = ref.watch(apiClientProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 100),
          child: Center(
            child: GestureDetector(
              onTap: vm.isUploadingPhoto ? null : () => _pickAndUploadPhoto(context, ref),
              child: Stack(
                children: [
                  _Avatar(
                    userId: user.idUsuario,
                    url: user.fotoPerfilUrl,
                    initials: user.iniciales,
                    isUploading: vm.isUploadingPhoto,
                    apiClient: apiClient,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2),
                      ),
                      child: Icon(Icons.camera_alt, size: 16, color: scheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 200),
          child: Center(
            child: Text(
              user.nombreCompleto,
              style: text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        FadeSlideIn(
          delay: const Duration(milliseconds: 250),
          child: Center(
            child: Text(
              user.rol.toUpperCase(),
              style: text.labelSmall?.copyWith(
                color: scheme.secondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        FadeSlideIn(
          delay: const Duration(milliseconds: 300),
          child: Row(
            children: [
              Text(
                'Datos personales',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (!_isEditing)
                TextButton.icon(
                  onPressed: vm.isSaving ? null : () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                )
              else
                TextButton(
                  onPressed: vm.isSaving
                      ? null
                      : () {
                          setState(() => _isEditing = false);
                          _initControllers(user);
                        },
                  child: const Text('Cancelar'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: _isEditing
              ? Column(
                  key: const ValueKey('edit'),
                  children: [
                    _buildField(_nombreCtrl, 'Nombre', scheme, text),
                    const SizedBox(height: 12),
                    _buildField(_apellidoPaternoCtrl, 'Apellido paterno', scheme, text),
                    const SizedBox(height: 12),
                    _buildField(_apellidoMaternoCtrl, 'Apellido materno (opcional)', scheme, text),
                    const SizedBox(height: 12),
                    _buildField(_telefonoCtrl, 'Telefono', scheme, text, keyboard: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildSexoField(scheme, text),
                    const SizedBox(height: 12),
                    _buildDateField(scheme, text),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: vm.isSaving ? null : () => _saveProfile(ref),
                        child: vm.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Guardar cambios'),
                      ),
                    ),
                  ],
                )
              : Card(
                  key: const ValueKey('view'),
                  child: Column(
                    children: [
                      _infoTile(Icons.person_outline, 'Nombre', user.nombre ?? 'Sin nombre', scheme),
                      _divider(scheme),
                      _infoTile(Icons.badge_outlined, 'Apellido paterno', user.apellidoPaterno ?? 'Sin apellido', scheme),
                      _divider(scheme),
                      _infoTile(Icons.badge_outlined, 'Apellido materno', user.apellidoMaterno ?? 'Sin apellido', scheme),
                      _divider(scheme),
                      _infoTile(Icons.phone_outlined, 'Telefono', user.telefono, scheme),
                      _divider(scheme),
                      _infoTile(Icons.email_outlined, 'Correo', user.correoElectronico ?? 'Sin correo', scheme),
                      _divider(scheme),
                      _infoTile(Icons.wc_outlined, 'Sexo', _sexoLabel(user.idSexo), scheme),
                      _divider(scheme),
                      _infoTile(
                        Icons.cake_outlined,
                        'Fecha de nacimiento',
                        user.fechaNacimiento != null
                            ? _formatDate(user.fechaNacimiento!)
                            : 'Sin dato',
                        scheme,
                      ),
                      _divider(scheme),
                      _infoTile(
                        Icons.event_outlined,
                        'Fecha de registro',
                        user.fechaRegistro != null
                            ? _formatDate(user.fechaRegistro!)
                            : 'Sin dato',
                        scheme,
                      ),
                    ],
                  ),
                ),
        ),

        if (vm.errorMessage != null) ...[
          const SizedBox(height: 16),
          JalaAlertBanner(
            message: vm.errorMessage!,
            onDismiss: () =>
                ref.read(profileViewModelProvider.notifier).clearError(),
          ),
        ],
        const SizedBox(height: 24),
        FadeSlideIn(
          delay: const Duration(milliseconds: 400),
          child: Text('Acciones',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        FadeSlideIn(
          delay: const Duration(milliseconds: 450),
          child: FilledButton.tonalIcon(
            onPressed: vm.isUploadingPhoto || vm.isDeleting
                ? null
                : () => _pickAndUploadPhoto(context, ref),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Cambiar foto de perfil'),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 500),
          child: OutlinedButton.icon(
            onPressed: vm.isDeleting
                ? null
                : () async {
                    await ref.read(profileViewModelProvider.notifier).logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesion'),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          delay: const Duration(milliseconds: 550),
          child: TextButton.icon(
            onPressed: vm.isDeleting
                ? null
                : () => _confirmDelete(context, ref),
            icon: Icon(Icons.delete_outline, color: scheme.error),
            label: Text(
              'Eliminar mi cuenta',
              style: TextStyle(color: scheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    ColorScheme scheme,
    TextTheme text, {
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: text.bodyLarge?.copyWith(color: scheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.isDark ? JalaBrand.amberDeep : JalaBrand.ink, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDateField(ColorScheme scheme, TextTheme text) {
    final display = _fechaNacimiento != null ? _formatDate(_fechaNacimiento!) : 'Sin fecha';
    return GestureDetector(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de nacimiento',
          labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          filled: true,
          fillColor: scheme.surfaceContainerLow,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          suffixIcon: Icon(Icons.calendar_today_outlined, color: scheme.onSurfaceVariant),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Text(
          display,
          style: text.bodyLarge?.copyWith(
            color: _fechaNacimiento != null ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSexoField(ColorScheme scheme, TextTheme text) {
    return DropdownButtonFormField<int>(
      initialValue: _idSexo,
      isExpanded: true,
      dropdownColor: scheme.surfaceContainerLow,
      decoration: InputDecoration(
        labelText: 'Sexo',
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.isDark ? JalaBrand.amberDeep : JalaBrand.ink, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: 1, child: Text('Masculino')),
        DropdownMenuItem(value: 2, child: Text('Femenino')),
        DropdownMenuItem(value: 3, child: Text('Otro')),
      ],
      onChanged: (value) => setState(() => _idSexo = value),
    );
  }

  String _sexoLabel(int? id) {
    switch (id) {
      case 1:
        return 'Masculino';
      case 2:
        return 'Femenino';
      case 3:
        return 'Otro';
      default:
        return 'Sin dato';
    }
  }

  Widget _infoTile(IconData icon, String label, String value, ColorScheme scheme) {
    return ListTile(
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(label),
      subtitle: Text(
        value,
        style: TextStyle(color: scheme.onSurface),
      ),
    );
  }

  Widget _divider(ColorScheme scheme) {
    return Divider(height: 1, indent: 16, color: scheme.outlineVariant.withValues(alpha: 0.3));
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _fechaNacimiento = picked);
    }
  }

  Future<void> _saveProfile(WidgetRef ref) async {
    final nombre = _nombreCtrl.text.trim();
    final apellidoPaterno = _apellidoPaternoCtrl.text.trim();
    final apellidoMaterno = _apellidoMaternoCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();

    if (nombre.isEmpty || apellidoPaterno.isEmpty || telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre, apellido paterno y telefono son obligatorios')),
      );
      return;
    }

    final ok = await ref.read(profileViewModelProvider.notifier).updateProfile(
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno.isEmpty ? '' : apellidoMaterno,
      idSexo: _idSexo,
      fechaNacimiento: _fechaNacimiento != null
          ? '${_fechaNacimiento!.year}-${_fechaNacimiento!.month.toString().padLeft(2, '0')}-${_fechaNacimiento!.day.toString().padLeft(2, '0')}'
          : null,
      telefono: telefono,
    );

    if (ok && mounted) {
      final freshUser = ref.read(profileViewModelProvider).user;
      if (freshUser != null) _initControllers(freshUser);
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    }
  }

  Future<void> _pickAndUploadPhoto(BuildContext context, WidgetRef ref) async {
    final source = await _askPhotoSource(context);
    if (source == null || !context.mounted) return;

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 88,
    );
    if (file == null || !context.mounted) return;

    final contentType = _resolveContentType(file);
    if (contentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formato no permitido. Usa JPG, PNG o WebP.'),
        ),
      );
      return;
    }

    final bytes = await file.readAsBytes();
    if (!context.mounted) return;

    final vm = ref.read(profileViewModelProvider.notifier);
    final ok = await vm.uploadNewPhoto(
      bytes: bytes,
      contentType: contentType,
      fileName: file.name,
    );
    if (!context.mounted) return;
    final state = ref.read(profileViewModelProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Foto actualizada'
              : (state.errorMessage ?? 'No se pudo actualizar la foto'),
        ),
        duration: ok ? const Duration(seconds: 3) : const Duration(seconds: 10),
      ),
    );
  }

  Future<ImageSource?> _askPhotoSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galeria'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String? _resolveContentType(XFile file) {
    final mime = file.mimeType?.toLowerCase();
    if (mime != null && _allowedImageMimeByExt.values.contains(mime)) {
      return mime;
    }
    final name = file.name.toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot < 0) return null;
    final ext = name.substring(dot + 1);
    return _allowedImageMimeByExt[ext];
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Tu cuenta sera eliminada y tu foto se borrara de '
          'forma definitiva. Quieres continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final vm = ref.read(profileViewModelProvider.notifier);
    final ok = await vm.deleteAccount();
    if (ok && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.userId,
    required this.url,
    required this.initials,
    required this.isUploading,
    required this.apiClient,
  });

  final int userId;
  final String? url;
  final String initials;
  final bool isUploading;
  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final base = ClipOval(
      child: Container(
        width: 96,
        height: 96,
        color: scheme.secondaryContainer,
        alignment: Alignment.center,
        child: url == null
            ? Text(
                initials,
                style: text.headlineMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              )
            : Image(
                image: AuthImageProvider(
                  userId: userId,
                  apiClient: apiClient,
                ),
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, error, _) {
                  debugPrint('[ProfileAvatar] No se pudo cargar la imagen: $error');
                  return Text(
                    initials,
                    style: text.headlineMedium?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
                frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  );
                },
              ),
      ),
    );

    if (!isUploading) return base;
    return Stack(
      alignment: Alignment.center,
      children: [
        base,
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
