import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quality & Forbidden Patterns Guard', () {
    final libDir = Directory('lib');

    late List<File> dartFiles;

    setUpAll(() {
      dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
    });

    test('Zero raw print() calls in lib/', () {
      final violations = <String>[];
      final regex = RegExp(r'\bprint\s*\(');

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (regex.hasMatch(line) && !line.trim().startsWith('//')) {
            violations.add('${file.path}:${i + 1} -> ${line.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Forbidden print() found in lib/:\n${violations.join('\n')}',
      );
    });

    test('Zero Color(0x...) literals outside app_theme.dart', () {
      final violations = <String>[];
      final regex = RegExp(r'Color\(0x[0-9a-fA-F]+\)');

      for (final file in dartFiles) {
        if (file.path.contains('app_theme.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (regex.hasMatch(line) && !line.trim().startsWith('//')) {
            violations.add('${file.path}:${i + 1} -> ${line.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Forbidden Color(0x...) outside app_theme.dart:\n${violations.join('\n')}',
      );
    });

    test('Zero Colors.<color> references outside app_theme.dart (except transparent)', () {
      final violations = <String>[];
      final regex = RegExp(r'(?<!App)Colors\.(?!transparent\b)[a-zA-Z]+');

      for (final file in dartFiles) {
        if (file.path.contains('app_theme.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (regex.hasMatch(line) && !line.trim().startsWith('//')) {
            violations.add('${file.path}:${i + 1} -> ${line.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Forbidden Colors.* outside app_theme.dart:\n${violations.join('\n')}',
      );
    });

    test('Zero TODO, FIXME, "Coming in Phase", or AIza API keys in lib/', () {
      final violations = <String>[];
      final regex = RegExp(r'(TODO|FIXME|Coming in Phase|AIza[0-9A-Za-z-_]{35})');

      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (regex.hasMatch(line)) {
            violations.add('${file.path}:${i + 1} -> ${line.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Forbidden placeholders / keys found in lib/:\n${violations.join('\n')}',
      );
    });

    test('Zero raw fontSize: outside app_theme.dart (except CustomPainter)', () {
      final violations = <String>[];
      final regex = RegExp(r'fontSize\s*:');

      for (final file in dartFiles) {
        if (file.path.contains('app_theme.dart') || file.path.contains('weekly_bar_chart.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (regex.hasMatch(line) && !line.trim().startsWith('//')) {
            violations.add('${file.path}:${i + 1} -> ${line.trim()}');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Forbidden fontSize: outside app_theme.dart:\n${violations.join('\n')}',
      );
    });
  });
}
