/// Pure Dart validator for AI-generated reason strings.
/// Rejects empty, long (>140 chars), date-referencing, or safety/freshness claiming reasons.
class ReasonValidator {
  ReasonValidator._();

  static final RegExp _datePattern = RegExp(
    r'\b(today|tomorrow|yesterday|\d+\s*days?|in\s+\d+|next\s+week)\b',
    caseSensitive: false,
  );

  static final RegExp _safetyFreshnessPattern = RegExp(
    r'\b(safe|safety|fresh|freshness|spoil|spoils|spoiled|spoiling|spoilage|still\s+good|okay\s+to\s+eat|ok\s+to\s+eat|healthy|guaranteed|no\s+risk)\b',
    caseSensitive: false,
  );

  /// Returns a sanitized, safe version of [reason].
  /// If the reason fails validation, returns a compliant fallback.
  static String sanitize(String? reason, {String fallback = 'Uses items that need rescue soon'}) {
    if (isValid(reason)) {
      return reason!.trim();
    }
    return fallback;
  }
  static bool isValid(String? reason) {
    if (reason == null) return false;
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length > 140) return false;
    if (_datePattern.hasMatch(trimmed)) return false;
    if (_safetyFreshnessPattern.hasMatch(trimmed)) return false;
    return true;
  }
}
