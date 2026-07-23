import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/auth/current_user_provider.dart';
import '../../../../../core/di/core_module.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../../../../theme/jala_theme.dart';
import '../../../../../theme/theme_mode_provider.dart';
import '../../../../auth/di/auth_module.dart';
import '../../../../favorites/presentation/provider/favorites_viewmodel.dart';
import '../../../../trip/trip-in-progress/domain/entities/trip.dart';
import '../../../../trip/trip-in-progress/presentation/provider/trip_in_progress_viewmodel.dart';
import '../../../../trip/trip-searching/domain/entities/trip_location.dart';
import '../../../../trip/trip-history/presentation/screens/trip_history_screen.dart';
import '../provider/passenger_home_viewmodel.dart';

class PassengerHomeScreen extends ConsumerStatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  ConsumerState<PassengerHomeScreen> createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends ConsumerState<PassengerHomeScreen> {
  MapboxMap? _mapboxMap;

  // ── Nav destinations ─────────────────────────────────────────────────
  static const _navDestinations = [
    JalaNavDestination(icon: Icons.home_rounded),
    JalaNavDestination(icon: Icons.receipt_long_rounded),
    JalaNavDestination(icon: Icons.person_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(passengerHomeViewModelProvider.notifier).loadUser();
      ref.read(favoritesViewModelProvider.notifier).load();
      ref.read(socketServiceProvider).connect();
    });
  }

  @override
  void dispose() {
    ref.read(socketServiceProvider).disconnect();
    super.dispose();
  }

  void _switchTab(int newIndex) {
    ref.read(passengerHomeViewModelProvider.notifier).selectTab(newIndex);
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
    final userName = user?.nombreParaMostrar ?? vm.greetingName;
    final userInitials = user?.iniciales ?? '?';
    final userSubtitle = user?.correoElectronico ?? user?.telefono ?? '';
    final selected = vm.selectedIndex;

    // Destinos guardados (favoritas) para la home: al tocar uno se abre el
    // flujo de viaje con origen = ubicacion actual y destino = el favorito.
    final savedAddresses = ref
        .watch(favoritesViewModelProvider)
        .items
        .map((d) => JalaSavedAddress(
              title: d.titulo,
              subtitle: (d.etiqueta != null &&
                      d.etiqueta!.isNotEmpty &&
                      d.texto != null &&
                      d.texto!.isNotEmpty)
                  ? d.texto!
                  : '',
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.tripSearching,
                arguments: TripLocation(
                  address: d.texto ?? d.titulo,
                  latitude: d.lat,
                  longitude: d.lng,
                  placeName: d.etiqueta,
                ),
              ),
            ))
        .toList();

    // Build the three tab contents once; IndexedStack keeps them alive.
    final tabs = [
      _HomeTabContent(
        key: const ValueKey('tab_home'),
        vm: vm,
        bottomPad: bottomPad,
        savedAddresses: savedAddresses,
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
          // Tabs con IndexedStack: se mantienen vivos (el mapa no se reinicia)
          // y solo se pinta el activo. Cambio instantaneo, sin el crossfade que
          // compositaba el mapa con saveLayer cada frame (causaba el jank).
          Positioned.fill(
            child: IndexedStack(
              index: selected,
              sizing: StackFit.expand,
              children: tabs,
            ),
          ),

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
    required this.savedAddresses,
    required this.onMapCreated,
    required this.onLocationTap,
    required this.onSearchTap,
    required this.onActiveTripTap,
  });

  final PassengerHomeViewModelState vm;
  final double bottomPad;
  final List<JalaSavedAddress> savedAddresses;
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
            iconColor: context.brand.accentBlue,
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
            savedAddresses: savedAddresses,
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
class _ProfileTabContent extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.idUsuario;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: JalaSidebar(
              userName: userName,
              userInitials: userInitials,
              userSubtitle: userSubtitle,
              userId: userId,
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
                  ],
                ),
                JalaSidebarSection(
                  label: 'PREFERENCIAS',
                  options: [
                    JalaSidebarOption(
                      icon: Icons.notifications_outlined,
                      label: 'Notificaciones',
                      onTap: () => _openNotificationSettings(context),
                    ),
                    JalaSidebarOption(
                      icon: Icons.bookmark_outline_rounded,
                      label: 'Direcciones favoritas',
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.favorites),
                    ),
                    JalaSidebarOption(
                      icon: Icons.dark_mode_outlined,
                      label:
                          'Tema: ${_themeModeLabel(ref.watch(themeModeProvider))}',
                      onTap: () => _pickThemeMode(context, ref),
                    ),
                  ],
                ),
                JalaSidebarSection(
                  label: 'SOPORTE',
                  options: [
                    JalaSidebarOption(
                      icon: Icons.help_outline_rounded,
                      label: 'Centro de ayuda',
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.helpCenter),
                    ),
                    JalaSidebarOption(
                      icon: Icons.description_outlined,
                      label: 'Términos y Condiciones',
                      onTap: () => _openUrl(context, 'https://terminos-y-condiciones-rosy.vercel.app/'),
                    ),
                    JalaSidebarOption(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Políticas de Privacidad',
                      onTap: () => _openUrl(context, 'https://politicas-de-privacidad-zeta.vercel.app/'),
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

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  Future<void> _pickThemeMode(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in const [
              (ThemeMode.light, Icons.light_mode_outlined, 'Claro'),
              (ThemeMode.dark, Icons.dark_mode_outlined, 'Oscuro'),
              (ThemeMode.system, Icons.brightness_auto_outlined, 'Sistema'),
            ])
              ListTile(
                leading: Icon(entry.$2),
                title: Text(entry.$3),
                trailing: entry.$1 == current
                    ? Icon(Icons.check_rounded, color: context.brand.success)
                    : null,
                onTap: () => Navigator.of(ctx).pop(entry.$1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) {
      ref.read(themeModeProvider.notifier).setMode(selected);
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[PassengerHome] No se pudo abrir $url: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  Future<void> _openNotificationSettings(BuildContext context) async {
    try {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No se pudo abrir la configuracion de notificaciones'),
          ),
        );
      }
    }
  }
}
