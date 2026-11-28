import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/freshness_ring.dart';
import '../../../../core/widgets/priority_chip.dart';
import '../../../ingredients/domain/entities/ingredient.dart';

class UrgencyStrip extends StatelessWidget {
  const UrgencyStrip({
    super.key,
    required this.expiringItems,
    required this.activeFocusIngredient,
    required this.onTapItem,
  });

  final List<Ingredient> expiringItems;
  final String? activeFocusIngredient;
  final ValueChanged<String> onTapItem;

  @override
  Widget build(BuildContext context) {
    if (expiringItems.isEmpty) return const SizedBox.shrink();

    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Urgent Food Radar',
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'Tap to prioritize',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 94,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
            scrollDirection: Axis.horizontal,
            itemCount: expiringItems.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = expiringItems[index];
              final isFocused = activeFocusIngredient != null &&
                  activeFocusIngredient!.toLowerCase() == item.name.toLowerCase();

              return _UrgentItemCard(
                item: item,
                today: today,
                isFocused: isFocused,
                onTap: () => onTapItem(item.name),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UrgentItemCard extends StatelessWidget {
  const _UrgentItemCard({
    required this.item,
    required this.today,
    required this.isFocused,
    required this.onTap,
  });

  final Ingredient item;
  final DateTime today;
  final bool isFocused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priority = item.priority(today: today);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 140,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isFocused
              ? AppColors.orange.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isFocused ? AppColors.orange : theme.dividerColor.withValues(alpha: 0.2),
            width: isFocused ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            FreshnessRing(
              ingredientName: item.name,
              daysLeft: item.daysLeft(today: today),
              size: 44,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.displayName,
                    style: context.text.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  PriorityChip(priority: priority),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
