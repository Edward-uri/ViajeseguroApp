import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/bubble_loader.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/domain/entities/user.dart';
import '../../../../shared/widgets/jala_alert_banner.dart';
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

    if (vm.user == null && vm.errorMessage != null && !vm.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
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
                  child: Text(
                    vm.errorMessage ?? 'No se pudo cargar el perfil',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
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

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(profileViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Center(
          child: _Avatar(
            url: user.fotoPerfilUrl,
            initials: user.iniciales,
            isUploading: vm.isUploadingPhoto,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            user.nombreCompleto,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            user.rol.toUpperCase(),
            style: text.labelSmall?.copyWith(
              color: scheme.secondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Card(
          child: ListTile(
            leading:
                Icon(Icons.event_outlined, color: scheme.onSurfaceVariant),
            title: const Text('Fecha de registro'),
            subtitle: Text(
              user.fechaRegistro != null
                  ? _formatDate(user.fechaRegistro!)
                  : 'Sin dato',
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
        Text('Acciones',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: vm.isUploadingPhoto || vm.isDeleting
              ? null
              : () => _pickAndUploadPhoto(context, ref),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Cambiar foto de perfil'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
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
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: vm.isDeleting
              ? null
              : () => _confirmDelete(context, ref),
          icon: Icon(Icons.delete_outline, color: scheme.error),
          label: Text(
            'Eliminar mi cuenta',
            style: TextStyle(color: scheme.error),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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
          content: Text('Formato no permitido. Usá JPG, PNG o WebP.'),
        ),
      );
      return;
    }

    final bytes = await file.readAsBytes();
    if (!context.mounted) return;

    final vm = ref.read(profileViewModelProvider.notifier);
    final ok = await vm.uploadNewPhoto(bytes: bytes, contentType: contentType);
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
              title: const Text('Elegir de la galería'),
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
          'Tu cuenta será eliminada y tu foto se borrará de '
          'forma definitiva. ¿Querés continuar?',
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
    required this.url,
    required this.initials,
    required this.isUploading,
  });

  final String? url;
  final String initials;
  final bool isUploading;

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
            : Image.network(
                url!,
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
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
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
