import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_error.dart';
import '../../../theme/jala_theme.dart';
import '../data/reportes_api.dart';

/// Motivos pasajero→conductor. El comentario es obligatorio solo en "Otro".
const _motivosConductor = <(String, String)>[
  ('conduccion_peligrosa', 'Conducción peligrosa'),
  ('falta_respeto', 'Falta de respeto'),
  ('cobro_indebido', 'Cobro indebido'),
  ('unidad_insegura', 'Unidad insegura'),
  ('no_se_presento', 'No se presentó'),
  ('otro', 'Otro'),
];

/// Abre la hoja para reportar al conductor de un viaje. Un reporte basta para
/// bloquearse mutuamente (no se les vuelve a asignar un viaje juntos).
Future<void> mostrarReportarConductorSheet(
  BuildContext context, {
  required int idViaje,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReportarConductorSheet(idViaje: idViaje),
  );
}

class _ReportarConductorSheet extends ConsumerStatefulWidget {
  const _ReportarConductorSheet({required this.idViaje});

  final int idViaje;

  @override
  ConsumerState<_ReportarConductorSheet> createState() =>
      _ReportarConductorSheetState();
}

class _ReportarConductorSheetState
    extends ConsumerState<_ReportarConductorSheet> {
  String? _motivo;
  final _comentario = TextEditingController();
  bool _enviando = false;
  bool _listo = false;
  bool _intentado = false;
  String? _error;

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  bool get _comentarioRequerido => _motivo == 'otro';
  bool get _comentarioOk =>
      !_comentarioRequerido || _comentario.text.trim().isNotEmpty;

  Future<void> _enviar() async {
    setState(() => _intentado = true);
    if (_motivo == null || !_comentarioOk) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref.read(reportesApiProvider).reportar(
            idViaje: widget.idViaje,
            motivo: _motivo!,
            comentario: _comentario.text,
          );
      if (!mounted) return;
      setState(() => _listo = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ErrorHandler.handle(e).message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: _listo ? _exito(context) : _formulario(context),
    );
  }

  Widget _exito(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Icon(Icons.check_circle_rounded, color: context.brand.success, size: 56),
        const SizedBox(height: 16),
        Text('Conductor reportado',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          'No se te volverán a asignar viajes con esta persona.',
          textAlign: TextAlign.center,
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ),
      ],
    );
  }

  Widget _formulario(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reportar conductor',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Cuéntanos qué pasó. Un reporte basta para bloquearse mutuamente.',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (final m in _motivosConductor)
            _MotivoTile(
              label: m.$2,
              selected: _motivo == m.$1,
              onTap: () => setState(() {
                _motivo = m.$1;
                _error = null;
              }),
            ),
          if (_intentado && _motivo == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Elige un motivo',
                  style: text.bodySmall?.copyWith(color: scheme.error)),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _comentario,
            maxLines: 3,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _comentarioRequerido
                  ? 'Comentario *'
                  : 'Comentario (opcional)',
              hintText: 'Describe lo que ocurrió',
              border: const OutlineInputBorder(),
              errorText: _intentado && !_comentarioOk
                  ? 'El comentario es obligatorio para "Otro"'
                  : null,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Al reportar, no se te asignarán más viajes con este conductor. No se puede deshacer.',
                    style: text.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: text.bodySmall?.copyWith(color: scheme.error)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              style: FilledButton.styleFrom(backgroundColor: scheme.error),
              icon: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.flag_outlined, size: 18),
              label: Text(_enviando ? 'Enviando…' : 'Reportar conductor'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MotivoTile extends StatelessWidget {
  const _MotivoTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}
