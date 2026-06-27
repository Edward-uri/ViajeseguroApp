import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../../core/auth/current_user_provider.dart';
import '../../../../../core/di/core_module.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../../../auth/di/auth_module.dart';
import '../../../../trip/trip-history/presentation/screens/trip_history_screen.dart';
import '../provider/passenger_home_viewmodel.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen> {
  MapboxMap? _mapboxMap;

  static const _navDestinations = [
    JalaNavDestination(icon: Icons.home_rounded),
    JalaNavDestination(icon: Icons.receipt_long_rounded),
    JalaNavDestination(icon: Icons.person_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(passengerHomeViewModelProvider.notifier).loadUser();
    });
  }

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
      debugPrint('Error obteniendo ubicación: $e');
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

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(passengerHomeViewModelProvider);
    final user = ref.watch(currentUserProvider);
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final userName = user?.nombreCompleto ?? vm.greetingName;
    final userInitials = user?.iniciales ?? '?';
    final userSubtitle = user?.correoElectronico ?? user?.telefono ?? '';

    return Scaffold(
      body: Stack(
        children: [
          // IndexedStack mantiene los 3 tabs montados: cambiar de tab solo
          // alterna cual se pinta. El MapWidget nativo de Mapbox ya NO se
          // destruye/recrea al ir a "Mis viajes" ni al volver a Home, y el
          // historial se construye una sola vez (sin jank de entrada).
          Positioned.fill(
            child: IndexedStack(
              index: vm.selectedIndex,
              children: [
                _buildHomeTab(vm, bottomPad, context),
                _buildTripsTab(),
                _buildProfileTab(context, userName, userInitials, userSubtitle),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: JalaBottomNavBar(
              selectedIndex: vm.selectedIndex,
              onTabSelected: (index) =>
                  ref.read(passengerHomeViewModelProvider.notifier).selectTab(index),
              destinations: _navDestinations,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(
    PassengerHomeViewModelState vm,
    double bottomPad,
    BuildContext context,
  ) {
    return Stack(
      children: [
        JalaMapView(
          onMapCreated: _onMapCreated,
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
            onTap: _getCurrentLocation,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 84 + bottomPad,
          child: JalaHomeBottomSheet(
            greetingName: vm.greetingName,
            onSearchTap: () {
              Navigator.of(context).pushNamed('/trip/searching');
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTripsTab() {
    return const TripHistoryScreen();
  }

  Widget _buildProfileTab(
    BuildContext context,
    String userName,
    String userInitials,
    String userSubtitle,
  ) {
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
              onLogout: () => _confirmLogout(context),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 84),
        ],
      ),
    );
  }
}
