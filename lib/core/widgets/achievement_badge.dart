import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class AchievementBadge extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final String? progressHint;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.progressHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color badgeBg = isUnlocked
        ? AppColors.lime.withValues(alpha: isDark ? 0.25 : 0.18)
        : theme.colorScheme.surfaceContainerHighest;

    final Color iconColor = isUnlocked
        ? AppColors.forest
        : theme.colorScheme.onSurfaceVariant;

    final Color titleColor = isUnlocked
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      label:
          '$title, ${isUnlocked ? "unlocked" : "locked"}${progressHint != null ? ", $progressHint" : ""}',
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: SizedBox(
          width: 140,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUnlocked
                        ? AppColors.lime
                        : theme.colorScheme.outlineVariant,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isUnlocked && progressHint != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    progressHint!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
