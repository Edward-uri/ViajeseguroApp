import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/widgets/widgets.dart';
import '../../../../../theme/jala_theme.dart';
import '../../../../reportes/presentation/reportar_sheet.dart';
import '../../../trip-in-progress/domain/entities/tipo_servicio.dart';
import '../../domain/entities/trip_history_item.dart';
import '../provider/trip_history_viewmodel.dart';

class TripHistoryScreen extends ConsumerStatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  ConsumerState<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
  // 0 = Todos, 1 = Viajes, 2 = Paquetes
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripHistoryViewModelProvider.notifier).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(tripHistoryViewModelProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;
    final items = _filter == 0
        ? vm.items
        : vm.items
            .where((i) => _filter == 2
                ? i.tipo == TipoServicio.envio
                : i.tipo != TipoServicio.envio)
            .toList();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16 + topPad, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Mis viajes',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    '${vm.totalEsteMes} viajes este mes',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: context.brand.greyDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: _FilterTabs(
                    selected: _filter,
                    onChanged: (i) => setState(() => _filter = i),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.items.isEmpty
                    ? _EmptyState(errorMessage: vm.errorMessage)
                    : items.isEmpty
                        ? _EmptyFilter(isPaquetes: _filter == 2)
                        : ListView.builder(
                            padding:
                                EdgeInsets.fromLTRB(24, 0, 24, 84 + bottomPad),
                            itemCount: items.length,
                            // Sin FadeSlideIn por item: al reciclarse durante el
                            // scroll re-disparaba la animacion (delay creciente)
                            // y las tarjetas "desaparecian" hasta soltar.
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _TripHistoryCard(item: items[index]),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  static const _labels = ['Todos', 'Viajes', 'Paquetes'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.brand.divider,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_labels.length, (index) {
          final isActive = selected == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: Container(
                decoration: BoxDecoration(
                  color: isActive ? context.colors.surfaceContainerLow : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: context.colors.onSurface
                                .withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[index],
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? context.colors.onSurface
                        : context.brand.greyDark,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            JalaAlertBanner(message: errorMessage!),
            const SizedBox(height: 16),
            Text(
              'No se pudieron cargar tus viajes',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.brand.greyDark,
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Text(
        'No tienes viajes aun',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: context.brand.greyDark,
        ),
      ),
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  const _EmptyFilter({required this.isPaquetes});

  final bool isPaquetes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        isPaquetes ? 'No tienes envios de paquete' : 'No tienes viajes',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: context.brand.greyDark,
        ),
      ),
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  const _TripHistoryCard({required this.item});

  final TripHistoryItem item;

  // static const: se asigna una sola vez, no se realoja por cada tarjeta
  // construida durante el scroll.
  static const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

  String _formatFecha(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 24 && now.day == date.day) {
      return 'Hoy · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.day == date.day && yesterday.month == date.month) {
      return 'Ayer · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day} ${_meses[date.month - 1]} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isCompletado = item.isCompletado;
    final isEnCurso = item.isEnCurso;
    final badgeColor = isCompletado
        ? context.brand.successLight
        : isEnCurso
            ? JalaBrand.amberLight
            : context.brand.destructiveLight;
    final badgeText = isCompletado
        ? context.brand.success
        : isEnCurso
            ? JalaBrand.amberDeep
            : context.brand.destructive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.brand.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: context.colors.onSurface.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.brand.accentSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  item.tipo == TipoServicio.envio
                      ? Icons.inventory_2_outlined
                      : Icons.two_wheeler_outlined,
                  size: 22,
                  color: JalaBrand.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatFecha(item.fecha),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.tipoLabel,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.brand.greyDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12.5),
                ),
                child: Text(
                  item.estadoLabel,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.brand.accentBlue,
                        width: 3,
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 16,
                    color: context.brand.greyBorder,
                  ),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: context.brand.accentBlue,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.originAddress,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.destinationAddress,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: context.brand.divider,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCompletado
                    ? '\$${item.tarifa.toStringAsFixed(2)}'
                    : '—',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
              Text(
                isCompletado ? item.metodoPago : 'Cancelado',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: context.brand.greyDark,
                ),
              ),
            ],
          ),
          if (isCompletado) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  final id = int.tryParse(item.id);
                  if (id != null) {
                    mostrarReportarConductorSheet(context, idViaje: id);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: context.brand.destructive,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.flag_outlined, size: 15),
                label: const Text('Reportar conductor',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
