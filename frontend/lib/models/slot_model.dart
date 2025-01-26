class Slot {
  final String startTime;
  final String endTime;
  bool isBooked;

  Slot({
    required this.startTime,
    required this.endTime,
    this.isBooked = false, // Default to false
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      startTime: json['startTime'],
      endTime: json['endTime'],
      isBooked: json['isBooked'] ?? false, // If the API provides it
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isBooked': isBooked,
    };
  }
}
