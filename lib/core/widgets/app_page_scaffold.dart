import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'responsive_builder.dart';

/// Standard, consistent page scaffold across all top-level tabs and screens.
/// Enforces safe area padding, responsive max content width, unified header hierarchy,
/// and consistent horizontal margins.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.actions,
    this.headerLeading,
    this.floatingActionButton,
    this.bottomSheet,
    this.scrollable = false,
    this.padding,
    required this.body,
  });

  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? headerLeading;
  final Widget? floatingActionButton;
  final Widget? bottomSheet;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHeader = title != null || titleWidget != null || subtitle != null || actions != null;

    final Widget header = hasHeader
        ? Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (headerLeading != null) ...[
                  headerLeading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (titleWidget != null)
                        titleWidget!
                      else if (title != null)
                        Text(
                          title!,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          )
        : const SizedBox.shrink();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasHeader) header,
        Expanded(
          child: scrollable
              ? SingleChildScrollView(
                  padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: body,
                )
              : Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: body,
                ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: ContentContainer(
          child: content,
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomSheet: bottomSheet,
    );
  }
}
