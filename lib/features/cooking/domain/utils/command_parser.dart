import 'dart:math';
import '../entities/voice_command.dart';

/// Pure Dart voice command parser.
/// Handles natural variations, filler word removal, Levenshtein distance 1 fuzzy matching,
/// number parsing, and running vs paused state context.
class CommandParser {
  static const _fillerWords = {
    'okay',
    'ok',
    'hey',
    'please',
    'can',
    'you',
    'could',
    'would',
    'the',
    'now',
    'just',
    'so',
  };

  static const _numberWords = {
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'first': 1,
    'second': 2,
    'third': 3,
    'fourth': 4,
    'fifth': 5,
  };

  static VoiceCommand parse(String input, {bool isPaused = false}) {
    final raw = input.trim();
    if (raw.isEmpty) {
      return const CommandUnknown('');
    }

    final cleaned = _cleanAndNormalize(raw);
    final tokens = cleaned.split(' ').where((s) => s.isNotEmpty).toList();
    if (tokens.isEmpty) {
      return CommandUnknown(raw);
    }

    // 1. Check for Next / Continue (when running)
    if (_matchesNext(tokens, isPaused: isPaused)) {
      return const CommandNext();
    }

    // 2. Check for Previous / Back
    if (_matchesPrevious(tokens)) {
      return const CommandPrevious();
    }

    // 3. Check for Repeat / Again
    if (_matchesRepeat(tokens)) {
      return const CommandRepeat();
    }

    // 4. Check for Pause / Stop / Wait / Hold on
    if (_matchesPause(tokens)) {
      return const CommandPause();
    }

    // 5. Check for Resume / Continue / Keep going / Unpause (when paused)
    if (_matchesResume(tokens, isPaused: isPaused)) {
      return const CommandResume();
    }

    // 6. Check for Start Over / Restart / From the beginning
    if (_matchesStartOver(tokens)) {
      return const CommandStartOver();
    }

    // 7. Check for Go to step X / Step X
    final stepNum = _extractStepNumber(tokens);
    if (stepNum != null) {
      return CommandGoToStep(stepNum);
    }

    // 8. Check for Finish / Done / Complete / I'm done
    if (_matchesFinish(tokens)) {
      return const CommandFinish();
    }

    // 9. Check for Exit / Quit / Leave / Close
    if (_matchesExit(tokens)) {
      return const CommandExit();
    }

    // 10. Check for List ingredients / What are the ingredients / What do I need
    if (_matchesListIngredients(tokens)) {
      return const CommandListIngredients();
    }

    // 11. Check for Tip / Tips / Advice / Any tips
    if (_matchesTip(tokens)) {
      return const CommandTip();
    }

    // 12. Check for Ask quantity: "how much / many [ingredient]"
    final quantityQuery = _extractQuantityQuery(cleaned);
    if (quantityQuery != null && quantityQuery.isNotEmpty) {
      return CommandAskQuantity(quantityQuery);
    }

    return CommandUnknown(raw);
  }

  static String _cleanAndNormalize(String text) {
    var s = text.toLowerCase();
    s = s.replaceAll(RegExp(r"[^\w\s]"), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static List<String> _stripFillers(List<String> tokens) {
    return tokens.where((t) => !_fillerWords.contains(t)).toList();
  }

  static bool _fuzzyMatch(String token, String target) {
    if (token == target) return true;
    if (target.length >= 4 && token.length >= 3) {
      return _levenshtein(token, target) <= 1;
    }
    return false;
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  static bool _matchesNext(List<String> tokens, {bool isPaused = false}) {
    final stripped = _stripFillers(tokens);
    if (stripped.isEmpty) return false;

    if (stripped.length == 1) {
      final t = stripped[0];
      if (_fuzzyMatch(t, 'next') || t == 'forward') return true;
      if (!isPaused && _fuzzyMatch(t, 'continue')) return true;
    }

    final phrase = stripped.join(' ');
    if (phrase == 'next step' ||
        phrase == 'go next' ||
        phrase == 'move forward' ||
        phrase == 'what next' ||
        phrase == 'whats next' ||
        phrase == 'and then' ||
        phrase == 'what is next') {
      return true;
    }

    return false;
  }

  static bool _matchesPrevious(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    if (stripped.isEmpty) return false;

    if (stripped.length == 1) {
      final t = stripped[0];
      return _fuzzyMatch(t, 'previous') || _fuzzyMatch(t, 'back') || t == 'prev' || _levenshtein(t, 'previous') <= 2;
    }

    final phrase = stripped.join(' ');
    if (phrase == 'go back' ||
        phrase == 'previous step' ||
        phrase == 'last step' ||
        phrase == 'step back') {
      return true;
    }

    return false;
  }

  static bool _matchesRepeat(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    if (stripped.isEmpty) return false;

    if (stripped.length == 1) {
      final t = stripped[0];
      return _fuzzyMatch(t, 'repeat') ||
          _fuzzyMatch(t, 'again') ||
          t == 'pardon' ||
          t == 'what';
    }

    final phrase = stripped.join(' ');
    final original = tokens.join(' ');
    if (phrase == 'say again' ||
        phrase == 'repeat that' ||
        phrase == 'read again' ||
        phrase == 'one more time' ||
        phrase == 'repeat step' ||
        original == 'what did you say' ||
        phrase == 'what did say') {
      return true;
    }

    return false;
  }

  static bool _matchesPause(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    if (stripped.isEmpty) return false;

    if (stripped.length == 1) {
      final t = stripped[0];
      return _fuzzyMatch(t, 'pause') || t == 'stop' || t == 'wait';
    }

    final phrase = stripped.join(' ');
    if (phrase == 'hold on' ||
        phrase == 'wait a second' ||
        phrase == 'pause cooking' ||
        phrase == 'take a break') {
      return true;
    }

    return false;
  }

  static bool _matchesResume(List<String> tokens, {required bool isPaused}) {
    final stripped = _stripFillers(tokens);
    if (stripped.isEmpty) return false;

    if (stripped.length == 1) {
      final t = stripped[0];
      if (_fuzzyMatch(t, 'resume') || _fuzzyMatch(t, 'unpause')) {
        return true;
      }
      if (isPaused && _fuzzyMatch(t, 'continue')) {
        return true;
      }
    }

    final phrase = stripped.join(' ');
    if (phrase == 'keep going' ||
        phrase == 'carry on' ||
        phrase == 'continue cooking' ||
        phrase == 'ready to continue' ||
        phrase == 'im ready' ||
        phrase == 'ready') {
      return true;
    }

    return false;
  }

  static bool _matchesStartOver(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    final phrase = stripped.join(' ');
    if (phrase == 'start over' ||
        phrase == 'restart' ||
        phrase == 'begin again' ||
        phrase == 'from beginning' ||
        phrase == 'from start' ||
        phrase == 'first step') {
      return true;
    }
    return false;
  }

  static int? _extractStepNumber(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    final phrase = stripped.join(' ');

    final stepRegExp = RegExp(r'(?:go\s+to\s+step|jump\s+to\s+step|step)\s+(\w+)');
    final match = stepRegExp.firstMatch(phrase);
    if (match != null) {
      final token = match.group(1)!;
      final intVal = int.tryParse(token);
      if (intVal != null && intVal > 0) return intVal;
      if (_numberWords.containsKey(token)) {
        return _numberWords[token];
      }
    }

    return null;
  }

  static bool _matchesFinish(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    if (stripped.isEmpty) return false;

    if (stripped.length == 1) {
      final t = stripped[0];
      return _fuzzyMatch(t, 'finish') || _fuzzyMatch(t, 'complete') || t == 'done';
    }

    final phrase = stripped.join(' ');
    if (phrase == 'im done' ||
        phrase == 'all done' ||
        phrase == 'finished cooking' ||
        phrase == 'finish recipe') {
      return true;
    }

    return false;
  }

  static bool _matchesExit(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    if (stripped.isEmpty) return false;

    if (stripped.length == 1) {
      final t = stripped[0];
      return _fuzzyMatch(t, 'exit') || _fuzzyMatch(t, 'quit') || _fuzzyMatch(t, 'leave') || _fuzzyMatch(t, 'close');
    }

    final phrase = stripped.join(' ');
    if (phrase == 'close recipe' ||
        phrase == 'exit cooking' ||
        phrase == 'quit cooking' ||
        phrase == 'leave cooking') {
      return true;
    }

    return false;
  }

  static bool _matchesListIngredients(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    final phrase = stripped.join(' ');

    if (phrase == 'ingredients' ||
        phrase == 'list ingredients' ||
        phrase == 'what ingredients' ||
        phrase == 'what do i need' ||
        phrase == 'what are ingredients' ||
        phrase == 'show ingredients' ||
        phrase == 'read ingredients') {
      return true;
    }

    return false;
  }

  static bool _matchesTip(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    final phrase = stripped.join(' ');

    if (phrase == 'tip' ||
        phrase == 'tips' ||
        phrase == 'any tips' ||
        phrase == 'give me a tip' ||
        phrase == 'cooking tip' ||
        phrase == 'what is the tip' ||
        phrase == 'got any tips' ||
        phrase == 'advice') {
      return true;
    }

    if (stripped.length == 1) {
      return _fuzzyMatch(stripped[0], 'tip') || _fuzzyMatch(stripped[0], 'tips');
    }

    return false;
  }

  static String? _extractQuantityQuery(String cleaned) {
    final patterns = [
      RegExp(r'how\s+much\s+(?:of\s+)?(.+)'),
      RegExp(r'how\s+many\s+(?:of\s+)?(.+)'),
      RegExp(r'amount\s+of\s+(.+)'),
      RegExp(r'quantity\s+of\s+(.+)'),
    ];

    for (final reg in patterns) {
      final match = reg.firstMatch(cleaned);
      if (match != null) {
        var query = match.group(1)!.trim();
        query = query.replaceAll(
          RegExp(r'\s+(do\s+i\s+need|to\s+add|required|needed|left)$'),
          '',
        );
        return query.trim();
      }
    }

    return null;
  }
}
