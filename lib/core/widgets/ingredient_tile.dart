import 'package:flutter/material.dart';

import '../domain/expiry_priority.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'freshness_ring.dart';
import 'priority_chip.dart';

class IngredientTile extends StatelessWidget {
  const IngredientTile({
    super.key,
    required this.name,
    required this.quantityLabel,
    required this.priority,
    required this.daysLeft,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String quantityLabel;
  final ExpiryPriority priority;
  final int? daysLeft;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final scheme = context.colors;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FreshnessRing(daysLeft: daysLeft),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: text.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  quantityLabel,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                PriorityChip(priority: priority, dense: true),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
