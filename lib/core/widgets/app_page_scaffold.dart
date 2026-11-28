import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'responsive_builder.dart';

/// Unified page scaffold across all top-level tabs and screens.
/// Enforces identical left-margin alignment (20 compact, 28 medium, 40 expanded),
/// Fraunces headline typography, safe area clearance, and consistent layout grid.
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

  static double horizontalPadding(double width) {
    if (width < 600) return 20.0;
    if (width < 840) return 28.0;
    return 40.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    // Responsive horizontal page padding: 20 compact (<600), 28 medium (600-840), 40 expanded (>840)
    final double pageHorizontalPadding = horizontalPadding(width);

    final hasHeader = title != null || titleWidget != null || subtitle != null || actions != null;

    final Widget header = hasHeader
        ? Padding(
            padding: EdgeInsets.only(
              left: pageHorizontalPadding,
              right: pageHorizontalPadding,
              top: AppSpacing.lg,
              bottom: AppSpacing.md,
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
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontFamily: AppTypography.headingFont,
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

    final defaultPadding = EdgeInsets.symmetric(
      horizontal: pageHorizontalPadding,
      vertical: AppSpacing.sm,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasHeader) header,
        Expanded(
          child: scrollable
              ? SingleChildScrollView(
                  padding: padding ?? defaultPadding,
                  child: body,
                )
              : Padding(
                  padding: padding ?? defaultPadding,
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
