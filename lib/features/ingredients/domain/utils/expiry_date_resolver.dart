/// Pure Dart utility to resolve relative expiry date phrases.
///
/// Supported phrases relative to a given `today`:
/// - "today"
/// - "tomorrow"
/// - "day after tomorrow"
/// - "in N days" / "in two days" (number words 1-10)
/// - "next week" (+7 days)
/// - Weekday names: "on Friday", "friday", "this friday", "next friday"
///   (Always upcoming Friday, strictly > today)
/// - "expires in two days"
/// - "N days ago" / "yesterday" (past, Expired)
///
/// Returns null for vague, unparseable, or unknown input. Never guesses.
abstract final class ExpiryDateResolver {
  static const Map<String, int> _numberWords = {
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

    // Exact matches
    if (clean == 'today') {
      return baseDate;
    }
    if (clean == 'tomorrow') {
      return baseDate.add(const Duration(days: 1));
    }
    if (clean == 'day after tomorrow' || clean == 'the day after tomorrow') {
      return baseDate.add(const Duration(days: 2));
    }
    if (clean == 'yesterday') {
      return baseDate.subtract(const Duration(days: 1));
    }
    if (clean == 'next week') {
      return baseDate.add(const Duration(days: 7));
    }

    // "N days ago"
    final RegExp daysAgoRegex = RegExp(r'^(\d+|[a-z]+)\s+days?\s+ago$');
    final Match? daysAgoMatch = daysAgoRegex.firstMatch(clean);
    if (daysAgoMatch != null) {
      final int? n = _parseNumber(daysAgoMatch.group(1)!);
      if (n != null) {
        return baseDate.subtract(Duration(days: n));
      }
    }

    // "(expires )?in N days"
    final RegExp inDaysRegex =
        RegExp(r'^(?:expires\s+)?in\s+(\d+|[a-z]+)\s+days?$');
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
        // Next upcoming weekday, never today or past
        daysAhead += 7;
      }
      return baseDate.add(Duration(days: daysAhead));
    }

    // Anything else (e.g. "some time soon", "a bit", "unknown") returns null
    return null;
  }

  static int? _parseNumber(String token) {
    final int? asInt = int.tryParse(token);
    if (asInt != null) return asInt;
    return _numberWords[token];
  }
}
