import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.title,
    required this.reason,
    required this.minutes,
    this.badges = const <String>[],
    this.substitution,
    this.featured = false,
    this.onTap,
  });

  final String title;
  final String reason;
  final int minutes;
  final List<String> badges;
  final String? substitution;
  final bool featured;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final scheme = context.colors;
    final Color fg = featured ? scheme.onPrimaryContainer : scheme.onSurface;
    final Color muted =
        featured ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return AppCard(
      onTap: onTap,
      color: featured ? scheme.primaryContainer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (featured) ...[
            Row(
              children: [
                Icon(Icons.bolt, size: AppSizes.iconSm, color: fg),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Top rescue pick',
                    style: text.labelMedium?.copyWith(color: fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            title,
            style: text.titleLarge?.copyWith(color: fg),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reason,
            style: text.bodyMedium?.copyWith(color: muted),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Pill(label: '$minutes min', icon: Icons.timer_outlined),
              for (final String badge in badges) _Pill(label: badge),
            ],
          ),
          if (substitution != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.swap_horiz, size: AppSizes.iconSm, color: fg),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    substitution!,
                    style: text.bodySmall?.copyWith(color: muted),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconSm, color: scheme.onSecondaryContainer),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: text.labelMedium?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
