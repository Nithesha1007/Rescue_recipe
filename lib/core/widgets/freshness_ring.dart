import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/expiry_priority.dart';
import '../domain/ingredient_emoji.dart';
import '../theme/app_theme.dart';

/// Circular countdown with ingredient emoji in center and animated ring.
class FreshnessRing extends StatelessWidget {
  const FreshnessRing({
    super.key,
    required this.daysLeft,
    this.ingredientName,
    this.maxDays = 7,
    this.size = AppSizes.ring,
  });

  final int? daysLeft;
  final String? ingredientName;
  final int maxDays;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = context.colors;
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

    final emoji = ingredientName != null
        ? IngredientEmoji.forIngredient(ingredientName!)
        : '🧺';

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
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
                child: SizedBox(
                  width: size * 0.6,
                  height: size * 0.6,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(emoji),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            days == null
                ? 'No date'
                : days < 0
                    ? 'Expired'
                    : days == 0
                        ? 'Today'
                        : '${days}d left',
            style: AppTypography.badgeTiny.copyWith(
              color: ringColor,
            ),
          ),
        ],
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
    final double radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final Paint progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    const double startAngle = -math.pi / 2;
    final double sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
