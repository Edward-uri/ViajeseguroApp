import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../routes/app_routes.dart';
import '../../../../../theme/theme.dart';
import '../../di/trip_in_progress_module.dart';
import '../../domain/entities/trip.dart';

/// Pantalla para que el pasajero califique al conductor al terminar el viaje.
class TripEvaluationScreen extends ConsumerStatefulWidget {
  const TripEvaluationScreen({super.key, required this.trip});

  final Trip trip;

  @override
  ConsumerState<TripEvaluationScreen> createState() => _TripEvaluationScreenState();
}

class _TripEvaluationScreenState extends ConsumerState<TripEvaluationScreen> {
  int _rating = 0;
  final _comentario = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  void _irAlHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.passengerHome,
      (route) => false,
    );
  }

  Future<void> _enviar() async {
    if (_rating == 0) {
      setState(() => _error = 'Toca una estrella para calificar.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref.read(tripRepositoryProvider).rateTrip(
            widget.trip.id,
            calificacion: _rating,
            comentario: _comentario.text.trim(),
          );
      if (mounted) _irAlHome();
    } catch (_) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _error = 'No pudimos enviar tu calificación. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final nombre = widget.trip.driverName ?? 'tu conductor';

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 48),
                Icon(Icons.check_circle_rounded, color: JalaBrand.success, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Viaje completado',
                  textAlign: TextAlign.center,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  '¿Cómo estuvo tu viaje con $nombre?',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final value = i + 1;
                    return IconButton(
                      onPressed: _enviando
                          ? null
                          : () => setState(() {
                                _rating = value;
                                _error = null;
                              }),
                      iconSize: 40,
                      icon: Icon(
                        value <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: JalaBrand.amber,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _comentario,
                  enabled: !_enviando,
                  maxLines: 3,
                  maxLength: 160,
                  decoration: InputDecoration(
                    hintText: 'Deja un comentario (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _enviando ? null : _enviar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JalaBrand.amber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _enviando ? 'Enviando…' : 'Enviar calificación',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _enviando ? null : _irAlHome,
                  child: const Text('Omitir'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
