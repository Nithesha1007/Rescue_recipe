import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  ScreenSize size,
  BoxConstraints constraints,
);

/// Builds a widget based on the width it is given (compact, medium, expanded).
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final ResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          builder(context, Responsive.sizeFor(constraints.maxWidth), constraints),
    );
  }
}

/// Centers content, caps its width and applies responsive page padding.
class ContentContainer extends StatelessWidget {
  const ContentContainer({super.key, required this.child, this.vertical = 0});

  final Widget child;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size, _) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.pagePadding(size),
              vertical: vertical,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Lays children out in 1, 2 or 3 columns depending on the available width.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = AppSpacing.lg,
    this.maxColumns = 3,
  });

  final List<Widget> children;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size, constraints) {
        final int columns = math.min(Responsive.columnsFor(size), maxColumns);
        final double width = Responsive.itemWidth(
          available: constraints.maxWidth,
          columns: columns,
          gap: spacing,
        );
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final Widget child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
