class Turf {
  final String id;
  final String name;
  final List<String> size;
  final List<String> imgPath;
  final List<String> sports;
  final List<String> facility;
  final double rate;
  final String link;
  final int booking_start;
  final int booking_end;
  final List<Map<String, dynamic>> daySlots;
  final List<Map<String, dynamic>> reviews;
  final Map<String, dynamic> location;

  Turf({
    required this.id,
    required this.name,
    required this.size,
    required this.imgPath,
    required this.sports,
    required this.facility,
    required this.rate,
    required this.link,
    required this.booking_start,
    required this.booking_end,
    required this.daySlots,
    required this.reviews,
    required this.location,
  });

  factory Turf.fromJson(Map<String, dynamic> json) {
    return Turf(
      id: json['_id'],
      name: json['name'],
      size: List<String>.from(json['size']),
      imgPath: List<String>.from(json['imgPath']),
      sports: List<String>.from(json['sports']),
      facility: List<String>.from(json['facility']),
      rate: double.parse(json['rate'].toString()),
      link: json['link'],
      booking_start: json['booking_start'],
      booking_end: json['booking_end'],
      daySlots: (json['daySlots'] as List)
          .map((slotJson) => {
                'date': DateTime.parse(slotJson['date']),
                'slots': (slotJson['slots'] as List)
                    .map((slot) => {
                          'startTime': slot['startTime'],
                          'endTime': slot['endTime'],
                          'status': slot['status']
                        })
                    .toList()
              })
          .toList(),
      reviews: (json['reviews'] as List)
          .map((reviewJson) => {
                'review': reviewJson['review'],
                'rating': reviewJson['rating'],
                'username': reviewJson['username']
              })
          .toList(),
      location: {
        'streetName': json['location']['streetName'],
        'city': json['location']['city'],
      },
    );
  }
}
