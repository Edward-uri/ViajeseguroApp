import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_provider.dart';
import '../../../../core/widgets/bubble_loader.dart';
import '../../../../theme/jala_theme.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/domain/entities/user.dart';
import '../../auth/di/auth_module.dart';
import '../../profile/di/profile_module.dart';
import '../../profile/domain/repositories/profile_repository.dart';

/// Splash de marca: siempre crema (igual que el launch screen nativo), así el
/// arranque es un solo flujo de color sin flashazos, en claro y oscuro.
/// El logo entra con escala + fade escalonados y el loader aparece después.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _minSplash = Duration(milliseconds: 950);

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 950),
    vsync: this,
  );

  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
  );

  late final Animation<double> _logoScale = Tween<double>(begin: 0.82, end: 1.0)
      .animate(CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
  ));

  late final Animation<Offset> _logoSlide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
  ));

  late final Animation<double> _loaderFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideRoute());
  }

  Future<void> _decideRoute() async {
    final authRepo = ref.read(authRepositoryProvider);
    final hasSession = await authRepo.hasSession();
    if (!hasSession) {
      await Future<void>.delayed(_minSplash);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      return;
    }
    // Con sesión: user en caché, /me enriquecido y el delay mínimo en paralelo.
    // El delay deja terminar la animación del logo; el /me (que trae el nombre,
    // ausente en el user de sesión) suele resolver dentro de ese tiempo, así el
    // home abre ya con el nombre y no con "Pasajero".
    final results = await Future.wait<dynamic>([
      authRepo.getCurrentUser(),
      _fetchFreshUser(ref.read(profileRepositoryProvider)),
      Future<void>.delayed(_minSplash),
    ]);
    final cachedUser = results[0] as User?;
    final freshUser = results[1] as User?;
    if (!mounted) return;
    final user = freshUser ?? cachedUser;
    if (user != null) {
      ref.read(currentUserProvider.notifier).setUser(user);
      Navigator.of(context).pushReplacementNamed(AppRoutes.passengerHome);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  /// /me para enriquecer el nombre; null si falla (sin conexión) para caer al
  /// usuario en caché sin romper el arranque.
  Future<User?> _fetchFreshUser(ProfileRepository repo) async {
    try {
      return await repo.getMe();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tamaño relativo al dispositivo (con límites) en vez de píxeles fijos:
    // se ve proporcionado igual en un teléfono chico que en una tablet.
    final size = MediaQuery.sizeOf(context);
    final logoWidth = (size.width * 0.62).clamp(220.0, 400.0);

    return Scaffold(
      backgroundColor: JalaBrand.cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _logoFade,
              child: SlideTransition(
                position: _logoSlide,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset(
                    'lib/shared/icons/logo_mototaxi_linea.png',
                    width: logoWidth,
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.05),
            FadeTransition(
              opacity: _loaderFade,
              child: const BubbleLoader(size: 20),
            ),
            SizedBox(height: size.height * 0.08),
          ],
        ),
      ),
    );
  }
}
