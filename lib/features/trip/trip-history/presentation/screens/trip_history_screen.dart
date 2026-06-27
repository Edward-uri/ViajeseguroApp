import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/widgets/jala_alert_banner.dart';
import '../../../../../theme/theme.dart';
import '../../domain/entities/trip_history_item.dart';
import '../provider/trip_history_viewmodel.dart';

class TripHistoryScreen extends ConsumerStatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  ConsumerState<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
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

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16 + topPad, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mis viajes',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: JalaBrand.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${vm.totalEsteMes} viajes este mes',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B6661),
                  ),
                ),
                const SizedBox(height: 16),
                const _FilterTabs(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.items.isEmpty
                    ? _EmptyState(errorMessage: vm.errorMessage)
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 84 + bottomPad),
                        itemCount: vm.items.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TripHistoryCard(item: vm.items[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterTabs extends StatefulWidget {
  const _FilterTabs();

  @override
  State<_FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends State<_FilterTabs> {
  int _selected = 0;
  static const _labels = ['Todos', 'Viajes', 'Paquetes'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_labels.length, (index) {
          final isActive = _selected == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selected = index),
              child: Container(
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isActive
                      ? const [
                          BoxShadow(
                            color: Color.fromRGBO(26, 20, 15, 0.12),
                            blurRadius: 4,
                            offset: Offset(0, 1),
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
                        ? JalaBrand.ink
                        : const Color(0xFF6B6661),
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
            const Text(
              'No se pudieron cargar tus viajes',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B6661),
              ),
            ),
          ],
        ),
      );
    }
    return const Center(
      child: Text(
        'No tienes viajes aun',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B6661),
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
    final badgeColor = isCompletado
        ? const Color(0xFFE6F4EA)
        : const Color(0xFFFCEAE6);
    final badgeText = isCompletado
        ? const Color(0xFF1E8E5A)
        : const Color(0xFFD84315);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(26, 20, 15, 0.06),
            blurRadius: 16,
            offset: Offset(0, 4),
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
                  color: const Color(0xFFFFF1E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  item.tipo.contains('paquete')
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
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: JalaBrand.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.tipo,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B6661),
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
                        color: const Color(0xFF005B9F),
                        width: 3,
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 16,
                    color: const Color(0xFFD1D1D1),
                  ),
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Color(0xFF005B9F),
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
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: JalaBrand.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.destinationAddress,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: JalaBrand.ink,
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
            color: const Color(0xFFECECEC),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCompletado
                    ? '\$${item.tarifa.toStringAsFixed(2)}'
                    : '—',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: JalaBrand.ink,
                ),
              ),
              Text(
                isCompletado ? item.metodoPago : 'Cancelado',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B6661),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
