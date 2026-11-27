import 'package:flutter/material.dart';

import '../domain/expiry_priority.dart';
import '../theme/app_theme.dart';

class PriorityChip extends StatelessWidget {
  const PriorityChip({
    super.key,
    required this.priority,
    this.label,
    this.dense = false,
  });

  final ExpiryPriority priority;
  final String? label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = context.text;
    return Semantics(
      label: 'Priority ${priority.label}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? AppSpacing.sm : AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: tokens.priorityColor(priority),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label ?? priority.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelMedium?.copyWith(
            color: tokens.onPriorityColor(priority),
          ),
        ),
      ),
    );
  }
}
