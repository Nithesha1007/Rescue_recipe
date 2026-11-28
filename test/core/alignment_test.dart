import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/core/widgets/app_page_scaffold.dart';

void main() {
  group('Alignment and Margins Contract', () {
    test('enforces identical responsive horizontal padding across all 5 app tabs', () {
      // 320dp - 411dp mobile (compact width < 600)
      expect(AppPageScaffold.horizontalPadding(320), equals(20.0));
      expect(AppPageScaffold.horizontalPadding(360), equals(20.0));
      expect(AppPageScaffold.horizontalPadding(411), equals(20.0));

      // Tablet / Medium width (600 <= width < 840)
      expect(AppPageScaffold.horizontalPadding(720), equals(28.0));

      // Desktop / Expanded width (>= 840)
      expect(AppPageScaffold.horizontalPadding(1024), equals(40.0));
    });
  });
}
