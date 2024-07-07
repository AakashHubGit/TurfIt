// slot_model.dart

class Slot {
  final String startTime;
  final String endTime;

  Slot({required this.startTime, required this.endTime});

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }
}
