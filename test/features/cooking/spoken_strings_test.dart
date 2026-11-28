import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/spoken_strings.dart';
import 'package:rescue_recipe/features/settings/domain/entities/user_preferences.dart';

void main() {
  group('SpokenStrings localized phrase tests', () {
    test('stepOfTotal formats correctly across all 4 languages', () {
      expect(SpokenStrings.stepOfTotal(2, 5, GuideLanguage.english), 'Step 2 of 5');
      expect(SpokenStrings.stepOfTotal(2, 5, GuideLanguage.tamil), 'படி 2 / 5');
      expect(SpokenStrings.stepOfTotal(2, 5, GuideLanguage.hindi), 'चरण 2 / 5');
      expect(SpokenStrings.stepOfTotal(2, 5, GuideLanguage.tanglish), 'Step 2 / 5');
    });

    test('firstStep phrases exist across all languages', () {
      expect(SpokenStrings.firstStep(GuideLanguage.english), contains('first step'));
      expect(SpokenStrings.firstStep(GuideLanguage.tamil), contains('முதல் படி'));
      expect(SpokenStrings.firstStep(GuideLanguage.hindi), contains('पहला चरण'));
      expect(SpokenStrings.firstStep(GuideLanguage.tanglish), contains('mudhal step'));
    });

    test('timer phrases exist across all languages', () {
      expect(SpokenStrings.timerStarted(5, GuideLanguage.english), 'Timer started for 5 minutes.');
      expect(SpokenStrings.timerStarted(5, GuideLanguage.tamil), contains('5 நிமிட'));
      expect(SpokenStrings.timerStarted(5, GuideLanguage.hindi), contains('5 मिनट'));
      expect(SpokenStrings.timerStarted(5, GuideLanguage.tanglish), contains('5 minutes timer'));

      expect(SpokenStrings.timerDone(GuideLanguage.english), contains('Time is up'));
      expect(SpokenStrings.timerDone(GuideLanguage.tamil), contains('முடிந்தது'));
      expect(SpokenStrings.timerDone(GuideLanguage.hindi), contains('समाप्त'));
    });

    test('foodSafetyDisclaimer contains quality and safety reminder in all languages', () {
      expect(SpokenStrings.foodSafetyDisclaimer(GuideLanguage.english), contains('inspect'));
      expect(SpokenStrings.foodSafetyDisclaimer(GuideLanguage.tamil), contains('பாதுகாப்பாக'));
      expect(SpokenStrings.foodSafetyDisclaimer(GuideLanguage.hindi), contains('सुरक्षा'));
      expect(SpokenStrings.foodSafetyDisclaimer(GuideLanguage.tanglish), contains('check'));
    });
  });
}
