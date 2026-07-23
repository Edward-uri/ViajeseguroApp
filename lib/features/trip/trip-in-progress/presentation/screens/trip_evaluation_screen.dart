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

    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Contenido scrolleable: badge, calificacion y reseña.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
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
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: context.brand.successLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: context.brand.success,
                              size: 46,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                        style: text.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                      Text(_error!,
                          style: TextStyle(color: scheme.error, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
            // Botones fijos abajo: siempre visibles sin necesidad de scroll.
            Container(
              padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(top: BorderSide(color: context.brand.divider)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 52,
                    width: double.infinity,
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _enviando
                          ? null
                          : () {
                              final id = int.tryParse(widget.trip.id);
                              if (id != null) {
                                mostrarReportarConductorSheet(context,
                                    idViaje: id);
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Reportar conductor',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  TextButton(
                    onPressed: _enviando ? null : _irAlHome,
                    child: const Text('Omitir'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
