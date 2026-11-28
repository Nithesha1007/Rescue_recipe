import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/voice_command.dart';
import 'package:rescue_recipe/features/cooking/domain/utils/command_parser.dart';

void main() {
  group('Multilingual CommandParser Tests', () {
    test('Tamil phrases (at least 25 variations)', () {
      final tamilTests = <String, Type>{
        // Next
        'அடுத்து': CommandNext,
        'அடுத்த படி': CommandNext,
        'அடுத்த ஸ்டெப் போ': CommandNext,
        'முன்னே போ': CommandNext,
        // Previous
        'முந்தைய படி': CommandPrevious,
        'பின்னே போ': CommandPrevious,
        'முந்தையது': CommandPrevious,
        'பின்னாடி போ': CommandPrevious,
        // Repeat
        'மீண்டும் சொல்': CommandRepeat,
        'திரும்ப சொல்லு': CommandRepeat,
        'மறுபடியும் வாசி': CommandRepeat,
        // Pause
        'நிறுத்து': CommandPause,
        'கொஞ்சம் நில்லு': CommandPause,
        'இடைநிறுத்து': CommandPause,
        // Resume
        'தொடரவும்': CommandResume,
        'தொடங்கு': CommandResume,
        'ஆரம்பி': CommandResume,
        // Start Over
        'மீண்டும் தொடங்கு': CommandStartOver,
        'முதலில் இருந்து வா': CommandStartOver,
        // Tip
        'குறிப்பு': CommandTip,
        'டிப்ஸ் சொல்லு': CommandTip,
        'யோசனை': CommandTip,
        // Timer
        'டைமர் வை': CommandStartTimer,
        'டைமர் நிறுத்து': CommandStopTimer,
        // Finish & Exit
        'சமையல் முடிந்தது': CommandFinish,
        'வெளியேறு': CommandExit,
      };

      for (final entry in tamilTests.entries) {
        final parsed = CommandParser.parse(entry.key);
        expect(parsed.runtimeType, entry.value, reason: 'Failed parsing Tamil phrase: "${entry.key}"');
      }
    });

    test('Hindi phrases (at least 25 variations)', () {
      final hindiTests = <String, Type>{
        // Next
        'आगे': CommandNext,
        'अगला': CommandNext,
        'अगला चरण': CommandNext,
        'आगे बढ़ो': CommandNext,
        // Previous
        'पीछे': CommandPrevious,
        'पिछला': CommandPrevious,
        'पिछला चरण': CommandPrevious,
        'पीछे जाओ': CommandPrevious,
        // Repeat
        'दोहराओ': CommandRepeat,
        'फिर से बोलो': CommandRepeat,
        'दोबारा कहो': CommandRepeat,
        // Pause
        'रुको': CommandPause,
        'ठहरो': CommandPause,
        'विराम': CommandPause,
        // Resume
        'जारी रखो': CommandResume,
        'शुरू करो': CommandResume,
        'आगे चलो': CommandResume,
        // Start Over
        'शुरू से': CommandStartOver,
        'दोबारा शुरू करो': CommandStartOver,
        // Tip
        'सुझाव': CommandTip,
        'टिप बताओ': CommandTip,
        'सलाह': CommandTip,
        // Timer
        'टाइमर लगाओ': CommandStartTimer,
        'टाइमर रोको': CommandStopTimer,
        // Finish & Exit
        'हो गया': CommandFinish,
        'पूरा हुआ': CommandFinish,
        'बाहर निकलो': CommandExit,
      };

      for (final entry in hindiTests.entries) {
        final parsed = CommandParser.parse(entry.key);
        expect(parsed.runtimeType, entry.value, reason: 'Failed parsing Hindi phrase: "${entry.key}"');
      }
    });

    test('Tanglish phrases (at least 25 variations)', () {
      final tanglishTests = <String, Type>{
        // Next
        'adutha step': CommandNext,
        'next polaam': CommandNext,
        'aduthadhu': CommandNext,
        'munnadi po': CommandNext,
        // Previous
        'pinnaadi': CommandPrevious,
        'previous step': CommandPrevious,
        'back po': CommandPrevious,
        'munthaiya step': CommandPrevious,
        // Repeat
        'marubadiyum sollu': CommandRepeat,
        'innoru thadava': CommandRepeat,
        'repeat pannu': CommandRepeat,
        // Pause
        'konjam nillu': CommandPause,
        'pause pannu': CommandPause,
        'wait pannu': CommandPause,
        // Resume
        'thodaru': CommandResume,
        'resume pannu': CommandResume,
        'start pannu': CommandResume,
        // Start Over
        'first-la irundhu': CommandStartOver,
        'start over': CommandStartOver,
        // Tip
        'tips iruka': CommandTip,
        'advice sollu': CommandTip,
        // Timer
        'timer vai': CommandStartTimer,
        'timer stop pannu': CommandStopTimer,
        // Finish & Exit
        'mudinjadhu': CommandFinish,
        'veliya po': CommandExit,
      };

      for (final entry in tanglishTests.entries) {
        final parsed = CommandParser.parse(entry.key);
        expect(parsed.runtimeType, entry.value, reason: 'Failed parsing Tanglish phrase: "${entry.key}"');
      }
    });

    test('Quantity questions in all languages', () {
      final q1 = CommandParser.parse('uppu evlo');
      expect(q1, isA<CommandAskQuantity>());
      expect((q1 as CommandAskQuantity).ingredientName, 'uppu');

      final q2 = CommandParser.parse('kitna namak');
      expect(q2, isA<CommandAskQuantity>());
      expect((q2 as CommandAskQuantity).ingredientName, 'namak');

      final q3 = CommandParser.parse('how much sugar');
      expect(q3, isA<CommandAskQuantity>());
      expect((q3 as CommandAskQuantity).ingredientName, 'sugar');
    });
  });
}
