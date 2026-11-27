/// Pure Dart expiry priority calculation rules.
enum ExpiryPriority {
  expired('Expired'),
  critical('Critical'),
  high('High'),
  medium('Medium'),
  low('Low'),
  unknown('Unknown');

  const ExpiryPriority(this.label);

  final String label;

  /// Calculates priority from calendar-day difference to [today].
  ///
  /// - days left < 0: Expired
  /// - 0: Critical
  /// - 1 to 2: High
  /// - 3 to 5: Medium
  /// - > 5: Low
  /// - no date: Unknown
  static ExpiryPriority fromDate(DateTime? expiryDate, {DateTime? today}) {
    if (expiryDate == null) return ExpiryPriority.unknown;
    final int days = daysLeft(expiryDate, today: today)!;
    return fromDaysLeft(days);
  }

  /// Calculates priority directly from integer [daysLeft].
  static ExpiryPriority fromDaysLeft(int? days) {
    if (days == null) return ExpiryPriority.unknown;
    if (days < 0) return ExpiryPriority.expired;
    if (days == 0) return ExpiryPriority.critical;
    if (days <= 2) return ExpiryPriority.high;
    if (days <= 5) return ExpiryPriority.medium;
    return ExpiryPriority.low;
  }

  /// Calculates calendar-day difference between [expiryDate] and [today],
  /// stripping time components.
  static int? daysLeft(DateTime? expiryDate, {DateTime? today}) {
    if (expiryDate == null) return null;
    final DateTime current = today ?? DateTime.now();
    final DateTime nowDateOnly = DateTime(current.year, current.month, current.day);
    final DateTime expDateOnly =
        DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expDateOnly.difference(nowDateOnly).inDays;
  }
}
