import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../../shared/widgets/jala_map_view.dart';
import '../../../../theme/jala_theme.dart';
import '../../../trip/trip-searching/di/trip_searching_module.dart';
import '../provider/favorites_viewmodel.dart';

/// Crea una direccion favorita eligiendo el punto en el mapa (pin naranja fijo
/// al centro; el usuario mueve el mapa) y reverse-geocoding al confirmar.
class CreateFavoriteScreen extends ConsumerStatefulWidget {
  const CreateFavoriteScreen({super.key});

  @override
  ConsumerState<CreateFavoriteScreen> createState() =>
      _CreateFavoriteScreenState();
}

class _CreateFavoriteScreenState extends ConsumerState<CreateFavoriteScreen> {
  final _nameController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onCameraChanged(CameraChangedEventData data) {
    final c = data.cameraState.center.coordinates;
    _lat = c.lat.toDouble();
    _lng = c.lng.toDouble();
  }

  Future<void> _save() async {
    if (_lat == null || _lng == null || _saving) return;
    setState(() => _saving = true);
    try {
      final loc =
          await ref.read(tripSearchRepositoryProvider).reverseGeocode(_lat!, _lng!);
      final name = _nameController.text.trim();
      final ok = await ref.read(favoritesViewModelProvider.notifier).crear(
            etiqueta: name.isEmpty ? null : name,
            lat: _lat!,
            lng: _lng!,
            texto: loc.address,
          );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Direccion guardada')),
        );
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la direccion')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la direccion')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: const Text('Nueva direccion'),
      ),
      body: Stack(
        children: [
          JalaMapView(
            onMapCreated: (_) {},
            showPinMarker: true,
            onCameraChanged: _onCameraChanged,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.onSurface.withValues(alpha: 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPad + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mueve el mapa para elegir el punto',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'El pin naranja marca el destino que se guardara.',
                    style: context.text.bodyMedium
                        ?.copyWith(color: context.brand.greyDark),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Nombre (opcional): Casa, Gym...',
                      filled: true,
                      fillColor: context.colors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.brand.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.brand.divider),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar direccion'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
