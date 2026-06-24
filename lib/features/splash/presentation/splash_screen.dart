import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user_provider.dart';
import '../../../../core/widgets/bubble_loader.dart';
import '../../../routes/app_routes.dart';
import '../../auth/di/auth_module.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideRoute());
  }

  Future<void> _decideRoute() async {
    final authRepo = ref.read(authRepositoryProvider);
    final results = await Future.wait<dynamic>([
      authRepo.hasSession(),
      authRepo.getCurrentUser(),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
    final hasSession = results[0] as bool;
    final user = results[1];
    if (!mounted) return;
    if (hasSession && user != null) {
      ref.read(currentUserProvider.notifier).setUser(user);
      Navigator.of(context).pushReplacementNamed(AppRoutes.passengerHome);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/shared/icons/logo_mototaxi_linea.png',
                  width: 320,
                  height: 240,
                ),
                const SizedBox(height: 40),
                const BubbleLoader(size: 20),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
