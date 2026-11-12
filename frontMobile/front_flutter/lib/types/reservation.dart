class ReservationCommonArea {
  const ReservationCommonArea({required this.id, required this.name, required this.limit});
  final String id;
  final String name;
  final int limit;

  factory ReservationCommonArea.fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['id'] is! String ||
        value['name'] is! String || value['limit'] is! int) {
      throw const FormatException('Invalid common area');
    }
    return ReservationCommonArea(id: value['id'] as String, name: value['name'] as String, limit: value['limit'] as int);
  }
}

class Reservation {
  const Reservation({required this.id, required this.residentName, required this.commonAreaId, required this.commonAreaName, required this.date});
  final String id;
  final String residentName;
  final String commonAreaId;
  final String commonAreaName;
  /// Calendar date, not a UTC instant.
  final DateTime date;

  factory Reservation.fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['id'] is! String ||
        value['residentName'] is! String || value['commonAreaId'] is! String ||
        value['commonAreaName'] is! String || value['reservationDate'] is! String) {
      throw const FormatException('Invalid reservation');
    }
    final date = parseReservationDate(value['reservationDate'] as String);
    if (date == null) throw const FormatException('Invalid reservation date');
    return Reservation(id: value['id'] as String, residentName: value['residentName'] as String,
      commonAreaId: value['commonAreaId'] as String, commonAreaName: value['commonAreaName'] as String, date: date);
  }
}

String reservationDateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime? parseReservationDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
  final parts = value.split('-').map(int.parse).toList();
  final date = DateTime(parts[0], parts[1], parts[2]);
  return reservationDateString(date) == value ? date : null;
}

DateTime reservationToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}
