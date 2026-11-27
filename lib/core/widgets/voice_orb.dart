import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Glowing orb with a CustomPainter waveform. [level] (0..1) is the speech
/// level and only has an effect while [active] is true.
class VoiceOrb extends StatefulWidget {
  const VoiceOrb({
    super.key,
    this.level = 0,
    this.active = false,
    this.size = AppSizes.orb,
    this.semanticLabel = 'Voice orb',
  });

  final double level;
  final bool active;
  final double size;
  final String semanticLabel;

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double available = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : widget.size;
            final double dimension = math.min(widget.size, available);
            final double target =
                widget.active ? widget.level.clamp(0.0, 1.0).toDouble() : 0.0;
            return SizedBox.square(
              dimension: dimension,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: target),
                duration: AppDurations.fast,
                builder: (context, level, _) => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => RepaintBoundary(
                    child: CustomPaint(
                      painter: _OrbPainter(
                        level: level,
                        phase: _controller.value * 2 * math.pi,
                        highlight: tokens.orbHighlight,
                        core: tokens.orbCore,
                        shade: tokens.orbShade,
                        accent: tokens.orbAccent,
                        glow: tokens.orbGlow,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter({
    required this.level,
    required this.phase,
    required this.highlight,
    required this.core,
    required this.shade,
    required this.accent,
    required this.glow,
  });

  final double level;
  final double phase;
  final Color highlight;
  final Color core;
  final Color shade;
  final Color accent;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double unit = size.shortestSide;
    final double breath = 1 + 0.03 * math.sin(phase);
    final double coreRadius = unit * 0.22 * breath * (1 + 0.1 * level);

    // Soft outer glow.
    final Rect glowRect = Rect.fromCircle(center: center, radius: unit / 2);
    canvas.drawCircle(
      center,
      unit / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            glow.withValues(alpha: 0.30 + 0.35 * level),
            glow.withValues(alpha: 0),
          ],
        ).createShader(glowRect),
    );

    // Three waveform rings. Integer multipliers keep the loop seamless.
    for (int k = 0; k < 3; k++) {
      final int lobes = 4 + k * 2;
      final double direction = k.isEven ? 1.0 : -1.0;
      final double base = coreRadius * (1.28 + 0.2 * k);
      final double amplitude =
          unit * (0.008 + 0.006 * k) + unit * 0.045 * level * (1 - 0.25 * k);

      final Path path = Path();
      const int steps = 120;
      for (int i = 0; i <= steps; i++) {
        final double angle = 2 * math.pi * i / steps;
        final double radius =
            base + amplitude * math.sin(angle * lobes + direction * phase * (k + 1));
        final Offset point =
            center + Offset(math.cos(angle), math.sin(angle)) * radius;
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * 0.01
          ..color = (k == 2 ? accent : core).withValues(alpha: 0.7 - 0.15 * k),
      );
    }

    // Core sphere.
    final Rect coreRect = Rect.fromCircle(center: center, radius: coreRadius);
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [highlight, core, shade],
          stops: const [0, 0.55, 1],
        ).createShader(coreRect),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.level != level ||
      old.phase != phase ||
      old.highlight != highlight ||
      old.core != core ||
      old.shade != shade ||
      old.accent != accent ||
      old.glow != glow;
}
