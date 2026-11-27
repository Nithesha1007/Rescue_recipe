import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/core/theme/app_theme.dart';

/// Calculates relative luminance according to WCAG 2.1 specifications:
/// https://www.w3.org/WAI/GL/wiki/Relative_luminance
double _relativeLuminance(Color color) {
  double channel(double value) {
    if (value <= 0.03928) {
      return value / 12.92;
    } else {
      return math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  // Flutter Color properties: r, g, b in range 0.0 .. 1.0
  final r = channel(color.r);
  final g = channel(color.g);
  final b = channel(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Calculates contrast ratio between two colors according to WCAG 2.1:
/// (L1 + 0.05) / (L2 + 0.05)
double _contrastRatio(Color c1, Color c2) {
  final l1 = _relativeLuminance(c1);
  final l2 = _relativeLuminance(c2);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('WCAG 2.1 Contrast Ratio Verification', () {
    test('Light theme key text and surface contrasts meet WCAG AA standards', () {
      final theme = AppTheme.light();
      final cs = theme.colorScheme;

      // 1. Primary on primaryContainer / primary
      final onPrimaryContrast = _contrastRatio(cs.onPrimary, cs.primary);
      expect(onPrimaryContrast, greaterThanOrEqualTo(4.5),
          reason: 'onPrimary on primary must meet 4.5:1');

      // 2. Primary text on surface (charcoal on cream)
      final textOnSurfaceContrast = _contrastRatio(cs.onSurface, cs.surface);
      expect(textOnSurfaceContrast, greaterThanOrEqualTo(4.5),
          reason: 'onSurface text on surface must meet 4.5:1');

      // 3. Critical text on surface
      final criticalContrast = _contrastRatio(AppColors.critical, cs.surface);
      expect(criticalContrast, greaterThanOrEqualTo(4.5),
          reason: 'Critical color on surface must meet 4.5:1');

      // 4. Forest green on surface
      final forestContrast = _contrastRatio(AppColors.forest, cs.surface);
      expect(forestContrast, greaterThanOrEqualTo(4.5),
          reason: 'Forest green on surface must meet 4.5:1');
    });

    test('Dark theme key text and surface contrasts meet WCAG AA standards', () {
      final theme = AppTheme.dark();
      final cs = theme.colorScheme;

      // 1. Text on dark surface
      final textOnDarkContrast = _contrastRatio(cs.onSurface, cs.surface);
      expect(textOnDarkContrast, greaterThanOrEqualTo(4.5),
          reason: 'Dark theme onSurface text on surface must meet 4.5:1');

      // 2. onPrimary on primary
      final onPrimaryContrast = _contrastRatio(cs.onPrimary, cs.primary);
      expect(onPrimaryContrast, greaterThanOrEqualTo(4.5),
          reason: 'Dark theme onPrimary on primary must meet 4.5:1');

      // 3. Orange action element on dark surface (3:0 minimum for large UI components)
      final orangeOnDark = _contrastRatio(cs.primary, cs.surface);
      expect(orangeOnDark, greaterThanOrEqualTo(3.0),
          reason: 'Primary orange on dark surface must meet at least 3.0:1 UI component ratio');
    });
  });
}
