import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../routes/app_routes.dart';
import '../../../../../shared/widgets/fade_slide_in.dart';
import '../../../../../theme/jala_theme.dart';
import '../../../../reportes/presentation/reportar_sheet.dart';
import '../../di/trip_in_progress_module.dart';
import '../../domain/entities/trip.dart';

/// Pantalla para que el pasajero califique al conductor al terminar el viaje.
/// Entrada escalonada (fade+slide) con badge de éxito animado y estrellas
/// con "pop" al seleccionar.
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
                // Badge de éxito: crece con rebote suave sobre fondo tenue.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.4, end: 1.0),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: context.brand.successLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: context.brand.success,
                          size: 52,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: Text(
                    'Viaje completado',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 260),
                  child: Text(
                    '¿Cómo estuvo tu viaje con $nombre?',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 340),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final value = i + 1;
                      final filled = value <= _rating;
                      return IconButton(
                        onPressed: _enviando
                            ? null
                            : () => setState(() {
                                  _rating = value;
                                  _error = null;
                                }),
                        iconSize: 40,
                        icon: AnimatedScale(
                          scale: filled ? 1.12 : 0.92,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: filled
                                ? JalaBrand.amber
                                : context.brand.greyBorder,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 420),
                  child: TextField(
                    controller: _comentario,
                    enabled: !_enviando,
                    maxLines: 3,
                    maxLength: 160,
                    decoration: InputDecoration(
                      hintText: 'Deja un comentario (opcional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(_error!, style: TextStyle(color: scheme.error, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 500),
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _enviar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: JalaBrand.amber,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _enviando ? 'Enviando…' : 'Enviar calificación',
                          key: ValueKey(_enviando),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 540),
                  child: TextButton.icon(
                    onPressed: _enviando
                        ? null
                        : () {
                            final id = int.tryParse(widget.trip.id);
                            if (id != null) {
                              mostrarReportarConductorSheet(context,
                                  idViaje: id);
                            }
                          },
                    icon: Icon(Icons.flag_outlined, size: 18, color: scheme.error),
                    label: Text('Reportar conductor',
                        style: TextStyle(color: scheme.error)),
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 560),
                  child: TextButton(
                    onPressed: _enviando ? null : _irAlHome,
                    child: const Text('Omitir'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
