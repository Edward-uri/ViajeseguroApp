import 'package:flutter/material.dart';

class PageTransitions {
  const PageTransitions._();

  static Route<T> fadeThrough<T>(Widget page, {Duration duration = const Duration(milliseconds: 350)}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: RepaintBoundary(child: child),
        );
      },
      transitionDuration: duration,
    );
  }

  static Route<T> slideUp<T>(Widget page, {Duration duration = const Duration(milliseconds: 350)}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetTween = Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        );
        final opacityTween = Tween<double>(begin: 0.0, end: 1.0);

        return SlideTransition(
          position: offsetTween.animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: opacityTween.animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: RepaintBoundary(child: child),
          ),
        );
      },
      transitionDuration: duration,
    );
  }

  static Route<T> slideRight<T>(Widget page, {Duration duration = const Duration(milliseconds: 300)}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetTween = Tween<Offset>(
          begin: const Offset(0.05, 0.0),
          end: Offset.zero,
        );
        final opacityTween = Tween<double>(begin: 0.0, end: 1.0);

        return SlideTransition(
          position: offsetTween.animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: opacityTween.animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: RepaintBoundary(child: child),
          ),
        );
      },
      transitionDuration: duration,
    );
  }

  static Route<T> sharedAxis<T>(Widget page, {Duration duration = const Duration(milliseconds: 350)}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  static Route<T> scaleFade<T>(Widget page, {Duration duration = const Duration(milliseconds: 300)}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleTween = Tween<double>(begin: 0.95, end: 1.0);
        final opacityTween = Tween<double>(begin: 0.0, end: 1.0);

        return ScaleTransition(
          scale: scaleTween.animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: opacityTween.animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: RepaintBoundary(child: child),
          ),
        );
      },
      transitionDuration: duration,
    );
  }
}

class FadeThroughTransition extends StatelessWidget {
  const FadeThroughTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final opacity = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ).value;

        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: child,
    );
  }
}
