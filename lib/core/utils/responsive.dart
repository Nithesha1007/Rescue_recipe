import '../theme/app_theme.dart';

enum ScreenSize {
  compact,
  medium,
  expanded;

  bool get isCompact => this == ScreenSize.compact;
  bool get isMedium => this == ScreenSize.medium;
  bool get isExpanded => this == ScreenSize.expanded;
}

abstract final class Responsive {
  /// Widths below this are compact.
  static const double compactMax = 600;

  /// Widths up to and including this are medium; above it, expanded.
  static const double mediumMax = 840;

  static ScreenSize sizeFor(double width) {
    if (width < compactMax) return ScreenSize.compact;
    if (width <= mediumMax) return ScreenSize.medium;
    return ScreenSize.expanded;
  }

  static int columnsFor(ScreenSize size) => switch (size) {
        ScreenSize.compact => 1,
        ScreenSize.medium => 2,
        ScreenSize.expanded => 3,
      };

  static double pagePadding(ScreenSize size) => switch (size) {
        ScreenSize.compact => AppSpacing.lg,
        ScreenSize.medium => AppSpacing.xl,
        ScreenSize.expanded => AppSpacing.xxl,
      };

  /// Width of one grid item so that [columns] items and their gaps fill
  /// [available] exactly.
  static double itemWidth({
    required double available,
    required int columns,
    required double gap,
  }) {
    return (available - gap * (columns - 1)) / columns;
  }
}
