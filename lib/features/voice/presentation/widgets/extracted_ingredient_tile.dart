import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/freshness_ring.dart';
import '../../../../core/widgets/priority_chip.dart';
import '../../domain/entities/extracted_ingredient.dart';

class ExtractedIngredientTile extends StatelessWidget {
  const ExtractedIngredientTile({
    super.key,
    required this.item,
    this.onTap,
    this.onDelete,
  });

  final ExtractedIngredient item;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

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
          FreshnessRing(daysLeft: item.daysLeft()),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.displayName,
                  style: text.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.quantityLabel,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PriorityChip(
                      priority: item.priority(),
                      label: item.resolvedExpiry != null
                          ? '${item.priority().label} (${item.daysLeft()! >= 0 ? "in ${item.daysLeft()}d" : "expired"})'
                          : 'No expiry date',
                      dense: true,
                    ),
                    if (!item.expiryUnderstood && item.expiryPhrase != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.medium,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'Unrecognized: "${item.expiryPhrase}"',
                          style: text.labelSmall?.copyWith(
                            color: AppColors.onMedium,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.critical),
              tooltip: 'Remove',
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
