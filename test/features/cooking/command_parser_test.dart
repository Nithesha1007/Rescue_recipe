import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/voice_command.dart';
import 'package:rescue_recipe/features/cooking/domain/utils/command_parser.dart';

void main() {
  group('CommandParser', () {
    test('parses Next variations', () {
      expect(CommandParser.parse('next'), isA<CommandNext>());
      expect(CommandParser.parse('next step'), isA<CommandNext>());
      expect(CommandParser.parse('go next'), isA<CommandNext>());
      expect(CommandParser.parse('move forward'), isA<CommandNext>());
      expect(CommandParser.parse('what next'), isA<CommandNext>());
      expect(CommandParser.parse('okay next please'), isA<CommandNext>());
      expect(CommandParser.parse('and then'), isA<CommandNext>());
      expect(CommandParser.parse('forward'), isA<CommandNext>());
      // Fuzzy (Levenshtein distance 1)
      expect(CommandParser.parse('nexxt'), isA<CommandNext>());
    });

    test('parses Previous / Back variations', () {
      expect(CommandParser.parse('back'), isA<CommandPrevious>());
      expect(CommandParser.parse('previous'), isA<CommandPrevious>());
      expect(CommandParser.parse('previous step'), isA<CommandPrevious>());
      expect(CommandParser.parse('go back'), isA<CommandPrevious>());
      expect(CommandParser.parse('step back'), isA<CommandPrevious>());
      expect(CommandParser.parse('last step'), isA<CommandPrevious>());
      expect(CommandParser.parse('prev'), isA<CommandPrevious>());
      // Fuzzy match
      expect(CommandParser.parse('previuos'), isA<CommandPrevious>());
    });

    test('parses Repeat variations', () {
      expect(CommandParser.parse('repeat'), isA<CommandRepeat>());
      expect(CommandParser.parse('again'), isA<CommandRepeat>());
      expect(CommandParser.parse('repeat that'), isA<CommandRepeat>());
      expect(CommandParser.parse('say again'), isA<CommandRepeat>());
      expect(CommandParser.parse('one more time'), isA<CommandRepeat>());
      expect(CommandParser.parse('what did you say'), isA<CommandRepeat>());
      expect(CommandParser.parse('pardon'), isA<CommandRepeat>());
    });

    test('parses Pause variations', () {
      expect(CommandParser.parse('pause'), isA<CommandPause>());
      expect(CommandParser.parse('stop'), isA<CommandPause>());
      expect(CommandParser.parse('wait'), isA<CommandPause>());
      expect(CommandParser.parse('hold on'), isA<CommandPause>());
      expect(CommandParser.parse('wait a second'), isA<CommandPause>());
      expect(CommandParser.parse('pause cooking'), isA<CommandPause>());
    });

    test('parses Resume / Continue variations', () {
      // In running mode: continue means next
      expect(CommandParser.parse('continue', isPaused: false), isA<CommandNext>());
      // In paused mode: continue means resume
      expect(CommandParser.parse('continue', isPaused: true), isA<CommandResume>());
      expect(CommandParser.parse('resume'), isA<CommandResume>());
      expect(CommandParser.parse('keep going'), isA<CommandResume>());
      expect(CommandParser.parse('carry on'), isA<CommandResume>());
      expect(CommandParser.parse('unpause'), isA<CommandResume>());
      expect(CommandParser.parse('im ready', isPaused: true), isA<CommandResume>());
    });

    test('parses Start Over variations', () {
      expect(CommandParser.parse('start over'), isA<CommandStartOver>());
      expect(CommandParser.parse('restart'), isA<CommandStartOver>());
      expect(CommandParser.parse('begin again'), isA<CommandStartOver>());
      expect(CommandParser.parse('from beginning'), isA<CommandStartOver>());
      expect(CommandParser.parse('from the beginning'), isA<CommandStartOver>());
      expect(CommandParser.parse('first step'), isA<CommandStartOver>());
    });

    test('parses GoToStep variations with numbers and words', () {
      final cmd1 = CommandParser.parse('go to step 3');
      expect(cmd1, isA<CommandGoToStep>());
      expect((cmd1 as CommandGoToStep).stepNumber, 3);

      final cmd2 = CommandParser.parse('step 5');
      expect((cmd2 as CommandGoToStep).stepNumber, 5);

      final cmd3 = CommandParser.parse('jump to step two');
      expect((cmd3 as CommandGoToStep).stepNumber, 2);

      final cmd4 = CommandParser.parse('go to step ten');
      expect((cmd4 as CommandGoToStep).stepNumber, 10);
    });

    test('parses Finish / Done variations', () {
      expect(CommandParser.parse('finish'), isA<CommandFinish>());
      expect(CommandParser.parse('done'), isA<CommandFinish>());
      expect(CommandParser.parse('im done'), isA<CommandFinish>());
      expect(CommandParser.parse('all done'), isA<CommandFinish>());
      expect(CommandParser.parse('finished cooking'), isA<CommandFinish>());
      expect(CommandParser.parse('complete'), isA<CommandFinish>());
    });

    test('parses Exit variations', () {
      expect(CommandParser.parse('exit'), isA<CommandExit>());
      expect(CommandParser.parse('quit'), isA<CommandExit>());
      expect(CommandParser.parse('leave'), isA<CommandExit>());
      expect(CommandParser.parse('close recipe'), isA<CommandExit>());
    });

    test('parses List ingredients variations', () {
      expect(CommandParser.parse('ingredients'), isA<CommandListIngredients>());
      expect(CommandParser.parse('list ingredients'), isA<CommandListIngredients>());
      expect(CommandParser.parse('what do i need'), isA<CommandListIngredients>());
      expect(CommandParser.parse('what are the ingredients'), isA<CommandListIngredients>());
    });

    test('parses Ask quantity variations', () {
      final cmd1 = CommandParser.parse('how much oil');
      expect(cmd1, isA<CommandAskQuantity>());
      expect((cmd1 as CommandAskQuantity).ingredientName, 'oil');

      final cmd2 = CommandParser.parse('how many eggs do i need');
      expect((cmd2 as CommandAskQuantity).ingredientName, 'eggs');

      final cmd3 = CommandParser.parse('amount of sugar needed');
      expect((cmd3 as CommandAskQuantity).ingredientName, 'sugar');

      final cmd4 = CommandParser.parse('quantity of milk required');
      expect((cmd4 as CommandAskQuantity).ingredientName, 'milk');
    });

    test('parses Tip variations', () {
      expect(CommandParser.parse('tip'), isA<CommandTip>());
      expect(CommandParser.parse('tips'), isA<CommandTip>());
      expect(CommandParser.parse('any tips'), isA<CommandTip>());
      expect(CommandParser.parse('give me a tip'), isA<CommandTip>());
      expect(CommandParser.parse('cooking tip'), isA<CommandTip>());
      expect(CommandParser.parse('what is the tip'), isA<CommandTip>());
    });

    test('parses unknown phrases as CommandUnknown', () {
      final unknown = CommandParser.parse('tell me a joke');
      expect(unknown, isA<CommandUnknown>());
      expect((unknown as CommandUnknown).rawText, 'tell me a joke');
    });
  });
}
