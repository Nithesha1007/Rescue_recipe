import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/priority_chip.dart';
import '../../../../core/widgets/section_header.dart';
import '../../domain/entities/inventory_deduction.dart';

class FinishConfirmationSheet extends StatelessWidget {
  final List<InventoryDeductionProposal> proposals;
  final ValueChanged<String> onToggle;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const FinishConfirmationSheet({
    super.key,
    required this.proposals,
    required this.onToggle,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SectionHeader(
                title: 'Update Inventory',
                subtitle: 'Confirm ingredients used in this recipe',
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: proposals.isEmpty
                    ? Center(
                        child: Text(
                          'No inventory items matched for deduction.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: proposals.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final item = proposals[index];
                          final actionLabel = item.action == DeductionAction.markUsed
                              ? 'Mark as completely used'
                              : 'Remaining: ${item.remainingQuantity} ${item.unit}';

                          return AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item.isConfirmed,
                                  activeColor: AppColors.orange,
                                  onChanged: (_) => onToggle(item.ingredientId),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.ingredientName,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        actionLabel,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PriorityChip(
                                  priority: item.priority,
                                  dense: true,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.outlined,
                      onPressed: onCancel,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Confirm & Save',
                      variant: AppButtonVariant.filled,
                      onPressed: onConfirm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        );
      },
    );
  }
}
