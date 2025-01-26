class Turf {
  final String id;
  final String name;
  final String size;
  final String location;
  final String admin;
  final String openTime;
  final String closeTime;
  final double price;
  final int slotDuration;
  final List<String> image; // Array of Base64 images

  Turf({
    required this.id,
    required this.name,
    required this.size,
    required this.location,
    required this.admin,
    required this.openTime,
    required this.closeTime,
    required this.price,
    required this.slotDuration,
    required this.image, // Array of Base64 images
  });

  factory Turf.fromJson(Map<String, dynamic> json) {
    return Turf(
      id: json['_id'],
      name: json['name'],
      size: json['size'],
      location: json['location'],
      admin: json['admin'],
      openTime: json['openTime'],
      closeTime: json['closeTime'],
      price: double.parse(json['price'].toString()),
      slotDuration: int.parse(json['slotDuration'].toString()),
      image: List<String>.from(
          json['images']), // Parse images as an array of strings
    );
  }
}
