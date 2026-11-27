import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/voice/domain/utils/transcript_accumulator.dart';

void main() {
  group('TranscriptAccumulator', () {
    test('initial state is completely empty', () {
      final acc = TranscriptAccumulator();
      expect(acc.liveTranscript, isEmpty);
      expect(acc.committedText, isEmpty);
      expect(acc.partialText, isEmpty);
      expect(acc.isEmpty, isTrue);
    });

    test('updates live partial text correctly', () {
      final acc = TranscriptAccumulator();
      acc.updatePartial('three tomatoes');
      expect(acc.partialText, 'three tomatoes');
      expect(acc.liveTranscript, 'three tomatoes');
      expect(acc.isEmpty, isFalse);
    });

    test('commits final segment and appends cleanly without duplicate spaces', () {
      final acc = TranscriptAccumulator();
      acc.commitSegment('three tomatoes');
      expect(acc.committedText, 'three tomatoes');
      expect(acc.partialText, isEmpty);
      expect(acc.liveTranscript, 'three tomatoes');

      acc.updatePartial('two');
      expect(acc.liveTranscript, 'three tomatoes two');

      acc.commitSegment('two onions');
      expect(acc.committedText, 'three tomatoes two onions');
      expect(acc.partialText, isEmpty);
      expect(acc.liveTranscript, 'three tomatoes two onions');
    });

    test('ignores duplicate exact final segment repetition', () {
      final acc = TranscriptAccumulator();
      acc.commitSegment('potatoes');
      acc.commitSegment('potatoes');
      expect(acc.committedText, 'potatoes');
    });

    test('tracks silent restarts and enforces max cap', () {
      final acc = TranscriptAccumulator();
      expect(acc.shouldRestart(maxSilentRestarts: 3), isTrue);
      acc.incrementRestart();
      expect(acc.silentRestartCount, 1);

      expect(acc.shouldRestart(maxSilentRestarts: 3), isTrue);
      acc.incrementRestart();
      expect(acc.silentRestartCount, 2);

      expect(acc.shouldRestart(maxSilentRestarts: 3), isTrue);
      acc.incrementRestart();
      expect(acc.silentRestartCount, 3);

      expect(acc.shouldRestart(maxSilentRestarts: 3), isFalse);
    });

    test('speech received resets silent restart counter and updates generation', () {
      final acc = TranscriptAccumulator();
      acc.incrementRestart();
      acc.incrementRestart();
      expect(acc.silentRestartCount, 2);

      final oldGen = acc.generation;
      final newGen = acc.nextGeneration();
      expect(newGen, oldGen + 1);

      acc.commitSegment('tomatoes');
      expect(acc.silentRestartCount, 0);
    });

    test('clear resets everything', () {
      final acc = TranscriptAccumulator();
      acc.commitSegment('milk');
      acc.updatePartial('bread');
      acc.incrementRestart();
      acc.clear();

      expect(acc.liveTranscript, isEmpty);
      expect(acc.committedText, isEmpty);
      expect(acc.partialText, isEmpty);
      expect(acc.silentRestartCount, 0);
      expect(acc.isEmpty, isTrue);
    });
  });
}
