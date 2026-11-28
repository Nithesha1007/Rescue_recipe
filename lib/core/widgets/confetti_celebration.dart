import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Lightweight custom confetti particle for celebration screens.
class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double rotation;
  double vr;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.vr,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color;
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

/// Self-animating confetti burst overlay respecting reduce-motion.
class ConfettiCelebration extends StatefulWidget {
  final Widget child;

  const ConfettiCelebration({super.key, required this.child});

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final _random = math.Random();

  static const _colors = [
    AppColors.confettiOrange,
    AppColors.confettiGreen,
    AppColors.confettiYellow,
    AppColors.confettiBlue,
    AppColors.confettiPurple,
    AppColors.confettiRed,
  ];

  @override
  void initState() {
    super.initState();
    _particles = List.generate(45, (_) {
      return _Particle(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.2,
        vx: (_random.nextDouble() - 0.5) * 0.3,
        vy: 0.4 + _random.nextDouble() * 0.6,
        size: 8 + _random.nextDouble() * 6,
        color: _colors[_random.nextInt(_colors.length)],
        rotation: _random.nextDouble() * math.pi * 2,
        vr: (_random.nextDouble() - 0.5) * 4,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..addListener(() {
        for (final p in _particles) {
          p.x += p.vx * 0.016;
          p.y += p.vy * 0.016;
          p.rotation += p.vr * 0.016;
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Stack(
      children: [
        widget.child,
        if (!reduceMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(_particles),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
