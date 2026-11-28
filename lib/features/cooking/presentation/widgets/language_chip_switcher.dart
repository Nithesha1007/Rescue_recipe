import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../settings/domain/entities/user_preferences.dart';

class LanguageChipSwitcher extends StatelessWidget {
  const LanguageChipSwitcher({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  final GuideLanguage selectedLanguage;
  final ValueChanged<GuideLanguage> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final options = [
      (GuideLanguage.english, 'English'),
      (GuideLanguage.tamil, 'தமிழ்'),
      (GuideLanguage.hindi, 'हिंदी'),
      (GuideLanguage.tanglish, 'Tanglish'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = selectedLanguage == opt.$1;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: FilterChip(
              label: Text(opt.$2),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.orange,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              labelStyle: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? AppColors.white
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => onLanguageSelected(opt.$1),
            ),
          );
        }).toList(),
      ),
    );
  }
}
