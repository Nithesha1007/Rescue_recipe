import 'dart:math';
import '../entities/voice_command.dart';

/// Pure Dart voice command parser.
/// Handles natural variations, filler word removal, Levenshtein distance 1 fuzzy matching,
/// number parsing, and running vs paused state context in English, Tamil, Hindi, and Tanglish.
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
    'konjam',
    'thoda',
    'bhai',
    'anna',
  };

  static const _numberWords = {
    // English
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

    // Tamil
    'ஒன்று': 1,
    'ஒன்னு': 1,
    'onnu': 1,
    'இரண்டு': 2,
    'ரெண்டு': 2,
    'rendu': 2,
    'மூன்று': 3,
    'மூணு': 3,
    'moonu': 3,
    'நான்கு': 4,
    'நாலு': 4,
    'naalu': 4,
    'ஐந்து': 5,
    'அஞ்சு': 5,
    'anju': 5,

    // Hindi
    'एक': 1,
    'ek': 1,
    'दो': 2,
    'do': 2,
    'तीन': 3,
    'teen': 3,
    'चार': 4,
    'chaar': 4,
    'char': 4,
    'पाँच': 5,
    'पांच': 5,
    'paanch': 5,
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

    // 11b. Check for Timer commands
    if (cleaned.contains('stop timer') ||
        cleaned.contains('cancel timer') ||
        cleaned.contains('timer stop') ||
        cleaned.contains('டைமரை நிறுத்து') ||
        cleaned.contains('timer niruthu') ||
        cleaned.contains('டைமர் நிறுத்து') ||
        cleaned.contains('टाइमर बंद करो') ||
        cleaned.contains('टाइमर रोको') ||
        cleaned.contains('timer roko') ||
        cleaned.contains('timer band karo')) {
      return const CommandStopTimer();
    }

    if (cleaned.contains('start timer') ||
        cleaned.contains('set timer') ||
        cleaned.contains('set a timer') ||
        cleaned.contains('timer podu') ||
        cleaned.contains('டைமர் போடு') ||
        cleaned.contains('டைமர் வை') ||
        cleaned.contains('timer lagao') ||
        cleaned.contains('टाइमर लगाओ') ||
        cleaned.contains('timer')) {
      final match = RegExp(r'(\d+)\s*(?:mins?|minutes?|நிமிடம்|நிமிஷம்|nimisham|minute|min|मिनट)?').firstMatch(cleaned);
      final minutes = match != null ? int.tryParse(match.group(1)!) : null;
      return CommandStartTimer(minutes);
    }

    // 12. Check for Ask quantity: "how much / many [ingredient]" / "uppu evlo" / "kitna namak"
    final quantityQuery = _extractQuantityQuery(cleaned);
    if (quantityQuery != null && quantityQuery.isNotEmpty) {
      return CommandAskQuantity(quantityQuery);
    }

    return CommandUnknown(raw);
  }

  static String _cleanAndNormalize(String text) {
    var s = text.toLowerCase();
    // Preserve letters, Devanagari (\u0900-\u097F), Tamil (\u0B80-\u0BFF), digits
    s = s.replaceAll(RegExp(r"[^\w\s\u0900-\u097F\u0B80-\u0BFF]"), ' ');
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

    final phrase = stripped.join(' ');
    if (phrase == 'next' ||
        phrase == 'forward' ||
        phrase == 'next step' ||
        phrase == 'go next' ||
        phrase == 'move forward' ||
        phrase == 'what next' ||
        phrase == 'whats next' ||
        phrase == 'and then' ||
        phrase == 'what is next' ||
        // Tamil / Tanglish
        phrase == 'aduthu' ||
        phrase == 'adutha step' ||
        phrase == 'next polaam' ||
        phrase == 'aduthadhu' ||
        phrase == 'munnadi po' ||
        phrase == 'muthalil' ||
        phrase == 'aduthathu' ||
        phrase == 'அடுத்து' ||
        phrase == 'அடுத்த படி' ||
        phrase == 'அடுத்தது' ||
        phrase == 'அடுத்த ஸ்டெப் போ' ||
        phrase == 'முன்னே போ' ||
        // Hindi
        phrase == 'aage' ||
        phrase == 'aage bado' ||
        phrase == 'agla' ||
        phrase == 'agla step' ||
        phrase == 'आगे' ||
        phrase == 'अगला' ||
        phrase == 'अगला चरण' ||
        phrase == 'अगला कदम' ||
        phrase == 'आगे बढ़ो') {
      return true;
    }

    if (stripped.length == 1) {
      final t = stripped[0];
      if (_fuzzyMatch(t, 'next') || t == 'forward') return true;
      if (!isPaused && (_fuzzyMatch(t, 'continue') || t == 'thodar')) return true;
    }

    return false;
  }

  static bool _matchesPrevious(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    if (stripped.isEmpty) return false;

    final phrase = stripped.join(' ');
    if (phrase == 'go back' ||
        phrase == 'previous step' ||
        phrase == 'last step' ||
        phrase == 'step back' ||
        phrase == 'munnadi' ||
        phrase == 'pinadi' ||
        phrase == 'pinnaadi' ||
        phrase == 'pinnaadi po' ||
        phrase == 'back po' ||
        phrase == 'munthaiya step' ||
        phrase == 'previous step' ||
        phrase == 'முந்தைய' ||
        phrase == 'முந்தைய படி' ||
        phrase == 'முந்தையது' ||
        phrase == 'பின்னே' ||
        phrase == 'பின்னே போ' ||
        phrase == 'பின்னாடி போ' ||
        phrase == 'peechhe' ||
        phrase == 'peeche' ||
        phrase == 'peeche jao' ||
        phrase == 'pichla' ||
        phrase == 'pichla step' ||
        phrase == 'पीछे' ||
        phrase == 'पिछला' ||
        phrase == 'पिछला चरण' ||
        phrase == 'पीछे जाओ' ||
        phrase == 'पिछला कदम') {
      return true;
    }

    if (stripped.length == 1) {
      final t = stripped[0];
      return _fuzzyMatch(t, 'previous') ||
          _fuzzyMatch(t, 'back') ||
          t == 'prev' ||
          t == 'previuos' ||
          t == 'பின்னாடி' ||
          t == 'piche';
    }

    return false;
  }

  static bool _matchesRepeat(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    if (stripped.isEmpty) return false;

    final phrase = stripped.join(' ');
    if (phrase == 'say again' ||
        phrase == 'repeat that' ||
        phrase == 'what did say' ||
        phrase == 'what did you say' ||
        phrase == 'read again' ||
        phrase == 'one more time' ||
        phrase == 'repeat step' ||
        phrase == 'thirumba sollu' ||
        phrase == 'marubadiyum sollu' ||
        phrase == 'innoru thadava' ||
        phrase == 'repeat pannu' ||
        phrase == 'மீண்டும் சொல்' ||
        phrase == 'திரும்ப சொல்லு' ||
        phrase == 'மறுபடியும் வாசி' ||
        phrase == 'மறுபடியும்' ||
        phrase == 'phir se bolo' ||
        phrase == 'dobaara bolo' ||
        phrase == 'dobara' ||
        phrase == 'dobara kaho' ||
        phrase == 'dohraao' ||
        phrase == 'फिर से बोलो' ||
        phrase == 'दोबारा कहो' ||
        phrase == 'दोहराओ' ||
        phrase == 'दोबारा') {
      return true;
    }

    if (stripped.length == 1) {
      final t = stripped[0];
      return _fuzzyMatch(t, 'repeat') ||
          _fuzzyMatch(t, 'again') ||
          t == 'pardon' ||
          t == 'thirumba' ||
          t == 'திரும்ப' ||
          t == 'phir se' ||
          t == 'दोबारा';
    }

    return false;
  }

  static bool _matchesPause(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    if (stripped.isEmpty) return false;

    final phrase = stripped.join(' ');
    if (phrase == 'hold on' ||
        phrase == 'wait a second' ||
        phrase == 'pause cooking' ||
        phrase == 'take a break' ||
        phrase == 'konjam nillu' ||
        phrase == 'iru' ||
        phrase == 'pause pannu' ||
        phrase == 'wait pannu' ||
        phrase == 'கொஞ்சம் நில்லு' ||
        phrase == 'நிறுத்து' ||
        phrase == 'இடைநிறுத்து' ||
        phrase == 'thodi der ruko' ||
        phrase == 'ruko' ||
        phrase == 'ruk jao' ||
        phrase == 'thahro' ||
        phrase == 'viraam' ||
        phrase == 'विराम' ||
        phrase == 'ठहरो' ||
        phrase == 'रुको' ||
        phrase == 'रुक जाओ') {
      return true;
    }

    if (stripped.length == 1) {
      final t = stripped[0];
      return _fuzzyMatch(t, 'pause') ||
          t == 'stop' ||
          t == 'wait' ||
          t == 'nillu' ||
          t == 'நில்' ||
          t == 'ruko' ||
          t == 'रुको';
    }

    return false;
  }

  static bool _matchesResume(List<String> tokens, {required bool isPaused}) {
    final stripped = _stripFillers(tokens);
    if (stripped.isEmpty) return false;

    final phrase = stripped.join(' ');
    if (phrase == 'keep going' ||
        phrase == 'carry on' ||
        phrase == 'continue cooking' ||
        phrase == 'ready to continue' ||
        phrase == 'im ready' ||
        phrase == 'aarambikkalam' ||
        phrase == 'thodaru' ||
        phrase == 'resume pannu' ||
        phrase == 'start pannu' ||
        phrase == 'தொடரு' ||
        phrase == 'தொடரவும்' ||
        phrase == 'தொடங்கு' ||
        phrase == 'ஆரம்பி' ||
        phrase == 'ஆரம்பிக்கலாம்' ||
        phrase == 'chalu karo' ||
        phrase == 'jaari rakho' ||
        phrase == 'shuru karo' ||
        phrase == 'aage chalo' ||
        phrase == 'शुरू करो' ||
        phrase == 'आगे चलो' ||
        phrase == 'चालू करो' ||
        phrase == 'जारी रखो') {
      return true;
    }

    if (stripped.length == 1) {
      final t = stripped[0];
      if (_fuzzyMatch(t, 'resume') || _fuzzyMatch(t, 'unpause')) return true;
      if (isPaused && (_fuzzyMatch(t, 'continue') || t == 'thodaru' || t == 'chalo')) return true;
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
        phrase == 'first step' ||
        phrase == 'first-la irundhu' ||
        phrase == 'first la irundhu' ||
        phrase == 'muthalilirunthu' ||
        phrase == 'marubadiyum aarambi' ||
        phrase == 'முதலில் இருந்து' ||
        phrase == 'மீண்டும் தொடங்கு' ||
        phrase == 'முதலில் இருந்து வா' ||
        phrase == 'shuru se' ||
        phrase == 'dobara shuru karo' ||
        phrase == 'दोबारा शुरू करो' ||
        phrase == 'phir se shuru karo' ||
        phrase == 'शुरू से') {
      return true;
    }
    return false;
  }

  static int? _extractStepNumber(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    final phrase = stripped.join(' ');

    final stepRegExp = RegExp(
      r'(?:go\s+to\s+step|jump\s+to\s+step|step|படி|படிக்கு\s+போ|step\s+ku\s+po|kadam)\s+([a-zA-Z0-9\u0900-\u097F\u0B80-\u0BFF]+)',
    );
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

    final phrase = stripped.join(' ');
    if (phrase == 'im done' ||
        phrase == 'all done' ||
        phrase == 'finished cooking' ||
        phrase == 'finish recipe' ||
        phrase == 'mudinjadhu' ||
        phrase == 'mudinjathu' ||
        phrase == 'samayal mudinjadhu' ||
        phrase == 'samayal mudinjathu' ||
        phrase == 'சமையல் முடிந்தது' ||
        phrase == 'முடிந்தது' ||
        phrase == 'samapt' ||
        phrase == 'khatam ho gaya' ||
        phrase == 'ho gaya' ||
        phrase == 'poora hua' ||
        phrase == 'पूरा हुआ' ||
        phrase == 'हो गया' ||
        phrase == 'ban gaya' ||
        phrase == 'बन गया' ||
        phrase == 'समाप्त') {
      return true;
    }

    if (stripped.length == 1) {
      final t = stripped[0];
      return _fuzzyMatch(t, 'finish') ||
          _fuzzyMatch(t, 'complete') ||
          t == 'done' ||
          t == 'mudinjathu' ||
          t == 'முடிந்தது' ||
          t == 'khatam' ||
          t == 'समाप्त';
    }

    return false;
  }

  static bool _matchesExit(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    if (stripped.isEmpty) return false;

    final phrase = stripped.join(' ');
    if (phrase == 'close recipe' ||
        phrase == 'exit cooking' ||
        phrase == 'quit cooking' ||
        phrase == 'leave cooking' ||
        phrase == 'veliye po' ||
        phrase == 'veliya po' ||
        phrase == 'moodu' ||
        phrase == 'வெளியேறு' ||
        phrase == 'வெளியே போ' ||
        phrase == 'bahar niklo' ||
        phrase == 'bahar jao' ||
        phrase == 'band karo' ||
        phrase == 'बाहर निकलो' ||
        phrase == 'बाहर जाओ') {
      return true;
    }

    if (stripped.length == 1) {
      final t = stripped[0];
      return _fuzzyMatch(t, 'exit') ||
          _fuzzyMatch(t, 'quit') ||
          _fuzzyMatch(t, 'leave') ||
          _fuzzyMatch(t, 'close') ||
          t == 'veliye' ||
          t == 'வெளியே' ||
          t == 'bahar' ||
          t == 'बाहर';
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
        phrase == 'read ingredients' ||
        phrase == 'thevaiana porutkal' ||
        phrase == 'thevaiyaana porulgal' ||
        phrase == 'தேவையான பொருட்கள்' ||
        phrase == 'kya chahiye' ||
        phrase == 'samagri' ||
        phrase == 'kya samaan chahiye' ||
        phrase == 'सामग्री' ||
        phrase == 'क्या चाहिए') {
      return true;
    }

    return false;
  }

  static bool _matchesTip(List<String> tokens) {
    final stripped = _stripFillers(tokens);
    final phrase = stripped.join(' ');

    if (phrase.contains('tip') ||
        phrase.contains('tips') ||
        phrase.contains('டிப்ஸ்') ||
        phrase.contains('டீப்ஸ்') ||
        phrase.contains('टिप') ||
        phrase.contains('advice') ||
        phrase.contains('kurippu') ||
        phrase.contains('குறிப்பு') ||
        phrase.contains('யோசனை') ||
        phrase.contains('sujhaav') ||
        phrase.contains('सुझाव') ||
        phrase.contains('सलाह')) {
      return true;
    }

    if (stripped.length == 1) {
      return _fuzzyMatch(stripped[0], 'tip') ||
          _fuzzyMatch(stripped[0], 'tips') ||
          stripped[0] == 'kurippu' ||
          stripped[0] == 'குறிப்பு';
    }

    return false;
  }

  static String? _extractQuantityQuery(String cleaned) {
    // English: "how much / many [ingredient]"
    final engPatterns = [
      RegExp(r'how\s+much\s+(?:of\s+)?(.+)'),
      RegExp(r'how\s+many\s+(?:of\s+)?(.+)'),
      RegExp(r'amount\s+of\s+(.+)'),
      RegExp(r'quantity\s+of\s+(.+)'),
    ];

    for (final reg in engPatterns) {
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

    // Tamil / Tanglish: "[ingredient] evlo" / "evlo [ingredient]" / "[ingredient] எவ்வளவு"
    final tamPatterns = [
      RegExp(r'(.+?)\s+(?:evlo|evvalavu|thevai|podanum|போடணும்)$'),
      RegExp(r'^(?:evlo|evvalavu|எவ்வளவு)\s+(.+)'),
      RegExp(r'(.+?)\s+எவ்வளவு$'),
    ];

    for (final reg in tamPatterns) {
      final match = reg.firstMatch(cleaned);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }

    // Hindi: "kitna [ingredient]" / "[ingredient] kitna chahiye" / "कितना [ingredient]"
    final hinPatterns = [
      RegExp(r'^(?:kitna|kitni|kitne|कितना|कितनी|कितने)\s+(.+)'),
      RegExp(r'(.+?)\s+(?:kitna|kitni|kitne|chahiye|daalna hai|डालना है)$'),
      RegExp(r'(.+?)\s+कितना$'),
    ];

    for (final reg in hinPatterns) {
      final match = reg.firstMatch(cleaned);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }

    return null;
  }
}
