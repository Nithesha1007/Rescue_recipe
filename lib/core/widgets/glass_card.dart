import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// [surface] is for normal backgrounds, [hero] for the dark gradient header.
enum GlassTone { surface, hero }

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.tone = GlassTone.surface,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
  });

  final Widget child;
  final GlassTone tone;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final BorderRadius radius = BorderRadius.circular(AppRadius.lg);
    final Color fill =
        tone == GlassTone.hero ? tokens.heroGlassFill : tokens.glassFill;
    final Color border =
        tone == GlassTone.hero ? tokens.heroGlassBorder : tokens.glassBorder;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.glassBlur,
          sigmaY: AppSizes.glassBlur,
        ),
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: border),
          ),
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  },
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
