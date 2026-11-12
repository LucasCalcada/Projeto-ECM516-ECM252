/// Parses a manually entered Brazilian date/time in the device's local zone.
/// Returns null for empty, incomplete or invalid input (including normalized dates).
DateTime? parseVisitorEntryDateTime(String value) {
  final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4}) (\d{2}):(\d{2})$')
      .firstMatch(value.trim());
  if (match == null) return null;
  final day = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final year = int.parse(match[3]!);
  final hour = int.parse(match[4]!);
  final minute = int.parse(match[5]!);
  if (year < 1 ||
      month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31 ||
      hour > 23 ||
      minute > 59) {
    return null;
  }
  final date = DateTime(year, month, day, hour, minute);
  if (date.year != year ||
      date.month != month ||
      date.day != day ||
      date.hour != hour ||
      date.minute != minute) {
    return null;
  }
  return date;
}
