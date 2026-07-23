import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../../shared/widgets/jala_map_view.dart';
import '../../../../theme/jala_theme.dart';
import '../../../trip/trip-searching/domain/entities/trip_location.dart';
import '../../../trip/trip-searching/di/trip_searching_module.dart';
import '../provider/favorites_viewmodel.dart';

/// Crea una direccion favorita: se puede buscar por direccion (sesgada a la
/// ciudad del pasajero) para centrar el mapa, y luego ajustar con el pin
/// naranja fijo al centro moviendo el mapa. Reverse-geocoding al guardar.
class CreateFavoriteScreen extends ConsumerStatefulWidget {
  const CreateFavoriteScreen({super.key});

  @override
  ConsumerState<CreateFavoriteScreen> createState() =>
      _CreateFavoriteScreenState();
}

class _CreateFavoriteScreenState extends ConsumerState<CreateFavoriteScreen> {
  MapboxMap? _map;
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _saving = false;

  Timer? _debounce;
  List<TripLocation> _results = const [];
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onCameraChanged(CameraChangedEventData data) {
    final c = data.cameraState.center.coordinates;
    _lat = c.lat.toDouble();
    _lng = c.lng.toDouble();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _searching = true);
      try {
        final results =
            await ref.read(tripSearchRepositoryProvider).searchAddress(
                  query,
                  // Sesga a la ubicacion (centro actual del mapa) del pasajero.
                  proximityLat: _lat,
                  proximityLng: _lng,
                );
        if (!mounted) return;
        setState(() {
          _results = results;
          _searching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _searching = false);
      }
    });
  }

  void _selectResult(TripLocation loc) {
    _lat = loc.latitude;
    _lng = loc.longitude;
    _searchController.text = loc.address;
    FocusScope.of(context).unfocus();
    setState(() => _results = const []);
    _map?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(loc.longitude, loc.latitude)),
        zoom: 16.0,
      ),
      MapAnimationOptions(duration: 900),
    );
  }

  Future<void> _save() async {
    if (_lat == null || _lng == null || _saving) return;
    setState(() => _saving = true);
    try {
      final loc = await ref
          .read(tripSearchRepositoryProvider)
          .reverseGeocode(_lat!, _lng!);
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
            onMapCreated: (m) => _map = m,
            showPinMarker: true,
            onCameraChanged: _onCameraChanged,
          ),
          // Buscador + resultados (arriba, sobre el mapa).
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                _SearchField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
                if (_searching || _results.isNotEmpty)
                  _SearchResults(
                    searching: _searching,
                    results: _results,
                    onSelect: _selectResult,
                  ),
              ],
            ),
          ),
          // Panel inferior: nombre + guardar.
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
              padding: EdgeInsets.fromLTRB(24, 18, 24, bottomPad + 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ajusta el pin naranja moviendo el mapa',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Busca una direccion arriba o mueve el mapa; el pin marca el punto que se guardara.',
                    style: context.text.bodyMedium
                        ?.copyWith(color: context.brand.greyDark),
                  ),
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 14),
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

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(14),
      color: context.colors.surface,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar direccion',
          prefixIcon: Icon(Icons.search, color: context.brand.greyDark),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close, color: context.brand.greyDark),
                  onPressed: onClear,
                ),
          filled: true,
          fillColor: context.colors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.brand.greyBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.brand.greyBorder),
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.searching,
    required this.results,
    required this.onSelect,
  });

  final bool searching;
  final List<TripLocation> results;
  final ValueChanged<TripLocation> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.brand.divider),
        boxShadow: [
          BoxShadow(
            color: context.colors.onSurface.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: searching && results.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: results.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: context.brand.divider,
              ),
              itemBuilder: (context, index) {
                final r = results[index];
                return ListTile(
                  leading: Icon(Icons.place_outlined, color: JalaBrand.amber),
                  title: Text(
                    r.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurface,
                    ),
                  ),
                  onTap: () => onSelect(r),
                );
              },
            ),
    );
  }
}
