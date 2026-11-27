import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_theme.dart';

/// Permanent safety note. Shown on every main screen.
class ExpiryDisclaimer extends StatelessWidget {
  const ExpiryDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final scheme = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: AppSizes.iconSm,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            AppStrings.expiryDisclaimer,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
