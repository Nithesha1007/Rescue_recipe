import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/expiry_priority.dart';
import '../theme/app_theme.dart';

/// Circular countdown. The arc shrinks and shifts green -> orange -> red as
/// the expiry date nears. [daysLeft] is null when there is no date.
class FreshnessRing extends StatelessWidget {
  const FreshnessRing({
    super.key,
    required this.daysLeft,
    this.maxDays = 7,
    this.size = AppSizes.ring,
  });

  final int? daysLeft;
  final int maxDays;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = context.colors;
    final text = context.text;
    final int? days = daysLeft;

    final double fraction = days == null
        ? 0
        : (days / maxDays).clamp(0.0, 1.0).toDouble();
    final double progress = days == null
        ? 0
        : (days <= 0 ? 0.06 : fraction.clamp(0.12, 1.0).toDouble());

    final Color ringColor;
    if (days == null) {
      ringColor = tokens.priorityColor(ExpiryPriority.unknown);
    } else if (days < 0) {
      ringColor = tokens.priorityColor(ExpiryPriority.expired);
    } else if (fraction < 0.5) {
      ringColor = Color.lerp(
        tokens.staleColor,
        tokens.priorityColor(ExpiryPriority.high),
        fraction * 2,
      )!;
    } else {
      ringColor = Color.lerp(
        tokens.priorityColor(ExpiryPriority.high),
        tokens.freshColor,
        (fraction - 0.5) * 2,
      )!;
    }

    final String centerLabel = days == null
        ? '?'
        : days < 0
            ? '!'
            : '$days';

    final String semantic = days == null
        ? 'No expiry date'
        : days < 0
            ? 'Expired'
            : days == 0
                ? 'Expires today'
                : days == 1
                    ? 'Expires in 1 day'
                    : 'Expires in $days days';

    return Semantics(
      label: semantic,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: progress),
          duration: AppDurations.slow,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => RepaintBoundary(
            child: CustomPaint(
              painter: _RingPainter(
                progress: value,
                color: ringColor,
                trackColor: scheme.outlineVariant,
                strokeWidth: AppSizes.ringStroke * (size / AppSizes.ring),
              ),
              child: child,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  centerLabel,
                  style: text.labelLarge?.copyWith(color: scheme.onSurface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - strokeWidth) / 2;

    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
