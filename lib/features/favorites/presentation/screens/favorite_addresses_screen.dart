import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/jala_theme.dart';
import '../../domain/entities/direccion.dart';
import '../provider/favorites_viewmodel.dart';

class FavoriteAddressesScreen extends ConsumerStatefulWidget {
  const FavoriteAddressesScreen({super.key});

  @override
  ConsumerState<FavoriteAddressesScreen> createState() =>
      _FavoriteAddressesScreenState();
}

class _FavoriteAddressesScreenState
    extends ConsumerState<FavoriteAddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favoritesViewModelProvider.notifier).load();
    });
  }

  Future<void> _confirmDelete(Direccion d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar direccion'),
        content: Text('¿Eliminar "${d.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(favoritesViewModelProvider.notifier).eliminar(d.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesViewModelProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: const Text('Direcciones favoritas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.createFavorite),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.items.isEmpty
              ? _EmptyFavorites(errorMessage: state.errorMessage)
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 96 + bottomPad),
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final d = state.items[index];
                    return _FavoriteCard(
                      direccion: d,
                      onDelete: () => _confirmDelete(d),
                    );
                  },
                ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.direccion, required this.onDelete});

  final Direccion direccion;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = direccion.etiqueta != null &&
        direccion.etiqueta!.isNotEmpty &&
        direccion.texto != null &&
        direccion.texto!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.brand.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.brand.accentSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.place_outlined, size: 22, color: JalaBrand.amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  direccion.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                  ),
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 2),
                  Text(
                    direccion.texto!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium
                        ?.copyWith(color: context.brand.greyDark),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Eliminar',
            icon: Icon(Icons.delete_outline_rounded, color: context.brand.destructive),
          ),
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border_rounded, size: 48, color: context.brand.greyDark),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'Aun no tienes direcciones favoritas',
              textAlign: TextAlign.center,
              style: context.text.bodyLarge?.copyWith(color: context.brand.greyDark),
            ),
            const SizedBox(height: 6),
            Text(
              'Toca "Agregar" para guardar un destino desde el mapa.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: context.brand.greyDark),
            ),
          ],
        ),
      ),
    );
  }
}
