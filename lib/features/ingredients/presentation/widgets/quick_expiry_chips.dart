import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Interactive quick expiry chips ("Today", "Tomorrow", "+3 days", "+1 week", "Pick date")
class QuickExpiryChips extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  const QuickExpiryChips({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final in3Days = today.add(const Duration(days: 3));
    final in1Week = today.add(const Duration(days: 7));

    bool isSameDay(DateTime? a, DateTime b) {
      if (a == null) return false;
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    final chips = [
      ('Today', today),
      ('Tomorrow', tomorrow),
      ('+3 days', in3Days),
      ('+1 week', in1Week),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        for (final chip in chips)
          ChoiceChip(
            label: Text(chip.$1),
            selected: isSameDay(selectedDate, chip.$2),
            selectedColor: AppColors.orange.withValues(alpha: 0.2),
            onSelected: (val) {
              if (val) {
                onDateSelected(chip.$2);
              } else {
                onDateSelected(null);
              }
            },
          ),
        ActionChip(
          avatar: const Icon(Icons.calendar_today_rounded, size: AppSizes.iconSm),
          label: const Text('Pick date'),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? today,
              firstDate: today.subtract(const Duration(days: 30)),
              lastDate: today.add(const Duration(days: 365)),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
        ),
      ],
    );
  }
}
