import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Row of dots showing progress through [count] steps. [current] is 0-based.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Semantics(
      label: 'Step ${current + 1} of $count',
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (int i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppDurations.fast,
              width: i == current ? AppSizes.dotActive : AppSizes.dot,
              height: AppSizes.dot,
              decoration: BoxDecoration(
                color: i <= current ? scheme.primary : scheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}
