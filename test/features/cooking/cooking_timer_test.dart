import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/voice_command.dart';
import 'package:rescue_recipe/features/cooking/domain/utils/command_parser.dart';

void main() {
  group('Cooking Timer Command Parsing', () {
    test('parses "start timer" command', () {
      final cmd1 = CommandParser.parse('start timer');
      expect(cmd1, isA<CommandStartTimer>());

      final cmd2 = CommandParser.parse('set a timer');
      expect(cmd2, isA<CommandStartTimer>());

      final cmd3 = CommandParser.parse('begin timer');
      expect(cmd3, isA<CommandStartTimer>());
    });

    test('parses "stop timer" command', () {
      final cmd1 = CommandParser.parse('stop timer');
      expect(cmd1, isA<CommandStopTimer>());

      final cmd2 = CommandParser.parse('cancel timer');
      expect(cmd2, isA<CommandStopTimer>());
    });

    test('parses standard navigation commands alongside timer', () {
      expect(CommandParser.parse('next step'), isA<CommandNext>());
      expect(CommandParser.parse('previous step'), isA<CommandPrevious>());
      expect(CommandParser.parse('repeat step'), isA<CommandRepeat>());
      expect(CommandParser.parse('pause'), isA<CommandPause>());
      expect(CommandParser.parse('resume'), isA<CommandResume>());
    });
  });
}
