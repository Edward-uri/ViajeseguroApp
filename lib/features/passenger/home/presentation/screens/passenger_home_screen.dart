import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../../core/auth/current_user_provider.dart';
import '../../../../../core/di/core_module.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../../../auth/di/auth_module.dart';
import '../../../../trip/trip-in-progress/domain/entities/trip.dart';
import '../../../../trip/trip-in-progress/presentation/provider/trip_in_progress_viewmodel.dart';
import '../../../../trip/trip-history/presentation/screens/trip_history_screen.dart';
import '../provider/passenger_home_viewmodel.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen>
    with SingleTickerProviderStateMixin {
  MapboxMap? _mapboxMap;

  // ── Tab crossfade animation ──────────────────────────────────────────
  late final AnimationController _tabAnim;
  int _prevTab = 0;

  // ── Nav destinations ─────────────────────────────────────────────────
  static const _navDestinations = [
    JalaNavDestination(icon: Icons.home_rounded),
    JalaNavDestination(icon: Icons.receipt_long_rounded),
    JalaNavDestination(icon: Icons.person_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(passengerHomeViewModelProvider.notifier).loadUser();
      ref.read(socketServiceProvider).connect();
    });
  }

  @override
  void dispose() {
    _tabAnim.dispose();
    ref.read(socketServiceProvider).disconnect();
    super.dispose();
  }

  // ── Tab switching with crossfade ─────────────────────────────────────
  void _switchTab(int newIndex) {
    final vm = ref.read(passengerHomeViewModelProvider.notifier);
    final current = ref.read(passengerHomeViewModelProvider).selectedIndex;
    if (newIndex == current) return;
    _prevTab = current;
    vm.selectTab(newIndex);
    _tabAnim
      ..reset()
      ..forward();
  }

  // ── Location helpers ─────────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) return;
      }
      if (permission == geo.LocationPermission.deniedForever) return;

      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      if (mounted) {
        _flyTo(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicacion: $e');
    }
  }

  void _flyTo(double latitude, double longitude) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: 16.0,
      ),
      MapAnimationOptions(duration: 1000, startDelay: 0),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
  }

  // ── Logout ───────────────────────────────────────────────────────────
  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await JalaDialog.confirm(
      context,
      title: 'Cerrar sesion',
      message: '¿Seguro que quieres cerrar sesion?',
      confirmText: 'Cerrar sesion',
      type: JalaAlertType.warning,
    );
    if (!ok || !context.mounted) return;

    final refreshToken =
        await ref.read(authStorageProvider).readRefreshToken();
    try {
      await ref.read(authRepositoryProvider).logout(
            refreshToken: refreshToken,
          );
    } catch (_) {}
    ref.read(currentUserProvider.notifier).clear();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // When trip is cancelled/completed from TripInProgressScreen, clear activeTrip immediately.
    ref.listen(tripInProgressViewModelProvider, (prev, next) {
      final status = next.trip?.status;
      if (status == TripStatus.completado || status == TripStatus.cancelado) {
        ref.read(passengerHomeViewModelProvider.notifier).clearActiveTrip();
      }
    });

    final vm = ref.watch(passengerHomeViewModelProvider);
    final user = ref.watch(currentUserProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final userName = user?.nombreCompleto ?? vm.greetingName;
    final userInitials = user?.iniciales ?? '?';
    final userSubtitle = user?.correoElectronico ?? user?.telefono ?? '';
    final selected = vm.selectedIndex;

    // Build the three tab contents once; IndexedStack keeps them alive.
    final tabs = [
      _HomeTabContent(
        key: const ValueKey('tab_home'),
        vm: vm,
        bottomPad: bottomPad,
        onMapCreated: _onMapCreated,
        onLocationTap: _getCurrentLocation,
        onSearchTap: () => Navigator.of(context).pushNamed('/trip/searching'),
        onActiveTripTap: () {
          final trip = vm.activeTrip;
          if (trip != null) {
            Navigator.of(context).pushNamed(
              AppRoutes.tripInProgress,
              arguments: trip,
            );
          }
        },
      ),
      const _TripsTabContent(key: ValueKey('tab_trips')),
      _ProfileTabContent(
        key: const ValueKey('tab_profile'),
        userName: userName,
        userInitials: userInitials,
        userSubtitle: userSubtitle,
        onLogout: () => _confirmLogout(context),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // ── Tabs with crossfade ─────────────────────────────────────
          ...List.generate(3, (i) {
            final isActive = i == selected;
            return Positioned.fill(
              child: AnimatedBuilder(
                animation: _tabAnim,
                builder: (context, _) {
                  final double opacity;
                  if (isActive) {
                    // Incoming tab: fades in 0 → 1
                    opacity = _tabAnim.value;
                  } else if (i == _prevTab) {
                    // Outgoing tab: fades out 1 → 0
                    opacity = 1.0 - _tabAnim.value;
                  } else {
                    opacity = 0.0;
                  }
                  return IgnorePointer(
                    ignoring: opacity < 0.01,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: tabs[i],
                    ),
                  );
                },
              ),
            );
          }),

          // ── Bottom nav bar ──────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: JalaBottomNavBar(
              selectedIndex: selected,
              onTabSelected: _switchTab,
              destinations: _navDestinations,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Home tab ────────────────────────────────────────────────────────────────
class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent({
    super.key,
    required this.vm,
    required this.bottomPad,
    required this.onMapCreated,
    required this.onLocationTap,
    required this.onSearchTap,
    required this.onActiveTripTap,
  });

  final PassengerHomeViewModelState vm;
  final double bottomPad;
  final void Function(MapboxMap) onMapCreated;
  final VoidCallback onLocationTap;
  final VoidCallback onSearchTap;
  final VoidCallback onActiveTripTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        JalaMapView(
          onMapCreated: onMapCreated,
          showLocationMarker: false,
          showCurrentLocationPin: true,
        ),
        Positioned(
          right: 24,
          bottom: 100 + bottomPad,
          child: JalaFloatingCircleButton(
            icon: Icons.my_location,
            iconColor: const Color(0xFF005B9F),
            iconSize: 24,
            onTap: onLocationTap,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 84 + bottomPad,
          child: JalaHomeBottomSheet(
            greetingName: vm.greetingName,
            activeTrip: vm.activeTrip,
            onSearchTap: onSearchTap,
            onActiveTripTap: onActiveTripTap,
          ),
        ),
      ],
    );
  }
}

// ── Trips tab ───────────────────────────────────────────────────────────────
class _TripsTabContent extends StatelessWidget {
  const _TripsTabContent({super.key});

  @override
  Widget build(BuildContext context) => const TripHistoryScreen();
}

// ── Profile tab ─────────────────────────────────────────────────────────────
class _ProfileTabContent extends StatelessWidget {
  const _ProfileTabContent({
    super.key,
    required this.userName,
    required this.userInitials,
    required this.userSubtitle,
    required this.onLogout,
  });

  final String userName;
  final String userInitials;
  final String userSubtitle;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: JalaSidebar(
              userName: userName,
              userInitials: userInitials,
              userSubtitle: userSubtitle,
              sections: [
                JalaSidebarSection(
                  label: 'CUENTA',
                  options: [
                    JalaSidebarOption(
                      icon: Icons.person_outline_rounded,
                      label: 'Mi perfil',
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.profile),
                    ),
                    JalaSidebarOption(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Metodos de pago',
                      onTap: () {},
                    ),
                    JalaSidebarOption(
                      icon: Icons.location_on_outlined,
                      label: 'Mis direcciones',
                      onTap: () {},
                    ),
                  ],
                ),
                JalaSidebarSection(
                  label: 'PREFERENCIAS',
                  options: [
                    JalaSidebarOption(
                      icon: Icons.notifications_outlined,
                      label: 'Notificaciones',
                      onTap: () {},
                    ),
                  ],
                ),
                JalaSidebarSection(
                  label: 'SOPORTE',
                  options: [
                    JalaSidebarOption(
                      icon: Icons.help_outline_rounded,
                      label: 'Centro de ayuda',
                      onTap: () {},
                    ),
                    JalaSidebarOption(
                      icon: Icons.description_outlined,
                      label: 'Terminos y privacidad',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
              onLogout: onLogout,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 84),
        ],
      ),
    );
  }
}
