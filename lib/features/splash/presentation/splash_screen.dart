import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/logo_badge.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../auth/domain/repositories/auth_repository.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideRoute());
  }

  Future<void> _decideRoute() async {
    final authRepo = context.read<AuthRepository>();
    final results = await Future.wait<dynamic>([
      authRepo.hasSession(),
      Future<void>.delayed(const Duration(milliseconds: 600)),
    ]);
    final hasSession = results[0] as bool;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      hasSession ? AppRoutes.profile : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 16),
              child: child,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LogoBadge(size: 148),
              const SizedBox(height: 28),
              Text(
                'Jala',
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tu mototaxi, a un toque',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: JalaBrand.amber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
