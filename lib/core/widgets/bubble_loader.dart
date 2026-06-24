import 'package:flutter/material.dart';

class BubbleLoader extends StatefulWidget {
  const BubbleLoader({super.key, this.color = const Color(0xFFFF8F00), this.size = 12});

  final Color color;
  final double size;

  @override
  State<BubbleLoader> createState() => _BubbleLoaderState();
}

class _BubbleLoaderState extends State<BubbleLoader>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animations = List.generate(3, (index) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.3, end: 1.0),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.3),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.3, end: 0.3),
          weight: 40,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            (index * 0.2) + 0.6,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : widget.size * 0.8,
                right: index == 2 ? 0 : widget.size * 0.8,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(
                  alpha: _animations[index].value,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
