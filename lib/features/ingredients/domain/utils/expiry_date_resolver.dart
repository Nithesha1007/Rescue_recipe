/// Pure Dart utility to resolve relative expiry date phrases in English, Tamil, Hindi, and Tanglish.
///
/// Supported phrases relative to a given `today`:
/// - "today", "இன்று", "இன்னைக்கு", "innaiku", "aaj", "आज"
/// - "tomorrow", "நாளை", "நாளைக்கு", "naalaikku", "kal", "कल"
/// - "day after tomorrow", "நாளை மறுநாள்", "naalai marunaal", "parson", "परसों"
/// - "in N days" / "இரண்டு நாளில்" / "दो दिन में" / "2 days la"
/// - "next week", "அடுத்த வாரம்", "agle hafte", "अगले हफ्ते"
/// - Weekday names (English and transliterations)
/// - "yesterday", "நேற்று", "நேத்து", "kal", "बीता कल"
///
/// Returns null for vague, unparseable, or unknown input. Never guesses.
abstract final class ExpiryDateResolver {
  static const Map<String, int> _numberWords = {
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

    // Tamil (script & Tanglish)
    'ஒன்று': 1,
    'ஒன்னு': 1,
    'onnu': 1,
    'oru': 1,
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
    'ஆறு': 6,
    'aaru': 6,
    'ஏழு': 7,
    'ezhu': 7,
    'எட்டு': 8,
    'ettu': 8,
    'ஒன்பது': 9,
    'onbathu': 9,
    'பத்து': 10,
    'pathu': 10,

    // Hindi (Devanagari & Romanized)
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
    'panch': 5,
    'छह': 6,
    'छः': 6,
    'chhah': 6,
    'che': 6,
    'सात': 7,
    'saat': 7,
    'sat': 7,
    'आठ': 8,
    'aath': 8,
    'aathh': 8,
    'नौ': 9,
    'nau': 9,
    'दस': 10,
    'das': 10,
  };

  static const Map<String, int> _weekdays = {
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };

  /// Resolves [phrase] into a calendar Date (year, month, day only, with no time).
  /// If [phrase] is null, empty, vague, or unrecognized, returns `null`.
  static DateTime? resolve(String? phrase, {DateTime? today}) {
    if (phrase == null) return null;
    final String clean = phrase.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final DateTime base = today ?? DateTime.now();
    final DateTime baseDate = DateTime(base.year, base.month, base.day);

    // Exact matches - Today
    if (clean == 'today' ||
        clean == 'இன்று' ||
        clean == 'இன்னைக்கு' ||
        clean == 'inniku' ||
        clean == 'innaiku' ||
        clean == 'iniku' ||
        clean == 'aaj' ||
        clean == 'आज') {
      return baseDate;
    }

    // Exact matches - Tomorrow
    if (clean == 'tomorrow' ||
        clean == 'நாளை' ||
        clean == 'நாளைக்கு' ||
        clean == 'naalai' ||
        clean == 'naalaiki' ||
        clean == 'naalaikku' ||
        clean == 'nalaiku' ||
        clean == 'kal' ||
        clean == 'कल' ||
        clean == 'aane wala kal' ||
        clean == 'आने वाला कल') {
      return baseDate.add(const Duration(days: 1));
    }

    // Exact matches - Day after tomorrow
    if (clean == 'day after tomorrow' ||
        clean == 'the day after tomorrow' ||
        clean == 'நாளை மறுநாள்' ||
        clean == 'மறுநாள்' ||
        clean == 'naalai marunaal' ||
        clean == 'marunal' ||
        clean == 'parson' ||
        clean == 'parso' ||
        clean == 'परसों' ||
        clean == 'परसो') {
      return baseDate.add(const Duration(days: 2));
    }

    // Exact matches - Yesterday
    if (clean == 'yesterday' ||
        clean == 'நேற்று' ||
        clean == 'நேத்து' ||
        clean == 'nethu' ||
        clean == 'netru' ||
        clean == 'beeta kal' ||
        clean == 'बीता कल') {
      return baseDate.subtract(const Duration(days: 1));
    }

    // Exact matches - Next week
    if (clean == 'next week' ||
        clean == 'அடுத்த வாரம்' ||
        clean == 'adutha vaaram' ||
        clean == 'agle hafte' ||
        clean == 'अगले हफ्ते') {
      return baseDate.add(const Duration(days: 7));
    }

    // "N days ago" / "N din pehle" / "N naal munnaadi"
    final RegExp daysAgoRegex = RegExp(
      r'^(\d+|[a-zA-Z\u0B80-\u0BFF\u0900-\u097F]+)\s+(?:days?\s+ago|நாட்களுக்கு\s+முன்பு|நாளுக்கு\s+முன்னாடி|naal\s+munnadi|din\s+pehle|दिन\s+पहले)$',
    );
    final Match? daysAgoMatch = daysAgoRegex.firstMatch(clean);
    if (daysAgoMatch != null) {
      final int? n = _parseNumber(daysAgoMatch.group(1)!);
      if (n != null) {
        return baseDate.subtract(Duration(days: n));
      }
    }

    // "(expires )?in N days" / "N days la" / "N din mein" / "N naalil"
    final RegExp inDaysRegex = RegExp(
      r'^(?:expires\s+)?(?:in\s+)?(\d+|[a-zA-Z\u0B80-\u0BFF\u0900-\u097F]+)\s*(?:days?|நாட்கள்|நாட்களில்|நாளில்|naatkal|naalil|naal\s*la|din\s*mein|din|दिन|दिनों\s+में|दिन\s+में)(?:\s+(?:la|mein|il))?$',
    );
    final Match? inDaysMatch = inDaysRegex.firstMatch(clean);
    if (inDaysMatch != null) {
      final int? n = _parseNumber(inDaysMatch.group(1)!);
      if (n != null) {
        return baseDate.add(Duration(days: n));
      }
    }

    // Weekday names ("on Friday", "friday", "this friday", "next friday")
    final RegExp weekdayRegex =
        RegExp(r'^(?:on\s+|this\s+|next\s+)?(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$');
    final Match? weekdayMatch = weekdayRegex.firstMatch(clean);
    if (weekdayMatch != null) {
      final String dayName = weekdayMatch.group(1)!;
      final int targetDay = _weekdays[dayName]!;
      int daysAhead = targetDay - baseDate.weekday;
      if (daysAhead <= 0) {
        daysAhead += 7;
      }
      return baseDate.add(Duration(days: daysAhead));
    }

    return null;
  }

  static int? _parseNumber(String token) {
    final int? asInt = int.tryParse(token);
    if (asInt != null) return asInt;
    return _numberWords[token];
  }
}
