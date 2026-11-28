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
    final tokens = context.tokens;
    final railColor = tokens.priorityColor(priority);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 4dp colored priority rail on the left
              Container(
                width: 5,
                color: railColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      FreshnessRing(
                        daysLeft: daysLeft,
                        ingredientName: name,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              quantityLabel.isNotEmpty ? quantityLabel : 'Quantity not given',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: PriorityChip(priority: priority, dense: true),
                            ),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
