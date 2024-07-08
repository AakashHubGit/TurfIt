class Booking {
  final String id;
  final String turfId;
  final DateTime date;
  final String startTime;
  final String endTime;

  Booking({
    required this.id,
    required this.turfId,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      turfId: json['turfId'],
      date: DateTime.parse(json['date']),
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'turfId': turfId,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
