import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

enum AppButtonVariant { filled, tonal, outlined, text, onHero }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.filled,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final tokens = context.tokens;

    final VoidCallback? handler = (onPressed == null || loading)
        ? null
        : () {
            HapticFeedback.lightImpact();
            onPressed!();
          };

    final Widget content = loading
        ? SizedBox.square(
            dimension: AppSizes.iconSm,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: scheme.onSurfaceVariant,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconSm),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final Widget button = switch (variant) {
      AppButtonVariant.filled =>
        FilledButton(onPressed: handler, child: content),
      AppButtonVariant.tonal =>
        FilledButton.tonal(onPressed: handler, child: content),
      AppButtonVariant.outlined =>
        OutlinedButton(onPressed: handler, child: content),
      AppButtonVariant.text => TextButton(onPressed: handler, child: content),
      AppButtonVariant.onHero => FilledButton(
          onPressed: handler,
          style: FilledButton.styleFrom(
            backgroundColor: tokens.heroAction,
            foregroundColor: tokens.onHeroAction,
          ),
          child: content,
        ),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
