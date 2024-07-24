class Booking {
  final String id;
  final String turfId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int totalPlayers;
  final int requestedPlayers;
  final List<JoinedPlayer> joinedPlayers;

  Booking({
    required this.id,
    required this.turfId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalPlayers,
    required this.requestedPlayers,
    required this.joinedPlayers,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Debug statements to check for null values
    print('id: ${json['_id']}');
    print('turfId: ${json['turf']}');
    print('date: ${json['date']}');
    print('startTime: ${json['startTime']}');
    print('endTime: ${json['endTime']}');
    print('totalPlayers: ${json['totalPlayers']}');
    print('requestedPlayers: ${json['requestedPlayers']}');
    print('joinedPlayers: ${json['joinedPlayers']}');

    return Booking(
      id: json['_id'],
      turfId: json['turf'],
      date: DateTime.parse(json['date']),
      startTime: json['startTime'],
      endTime: json['endTime'],
      totalPlayers: json['totalPlayers'],
      requestedPlayers: json['requestedPlayers'],
      joinedPlayers: List<JoinedPlayer>.from(
        json['joinedPlayers'].map((jp) => JoinedPlayer.fromJson(jp)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'turfId': turfId,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'totalPlayers': totalPlayers,
      'requestedPlayers': requestedPlayers,
      'joinedPlayers': joinedPlayers.map((jp) => jp.toJson()).toList(),
    };
  }
}

class JoinedPlayer {
  final String userId;
  final String userName;
  final int playersCount;
  final double price;

  JoinedPlayer({
    required this.userId,
    required this.userName,
    required this.playersCount,
    required this.price,
  });

  factory JoinedPlayer.fromJson(Map<String, dynamic> json) {
    // Debug statements to check for null values
    print('userId: ${json['user']}');
    print('userName: ${json['userName']}');
    print('playersCount: ${json['playersCount']}');
    print('price: ${json['price']}');

    return JoinedPlayer(
      userId: json['user'],
      userName: json['userName'],
      playersCount: json['playersCount'],
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'playersCount': playersCount,
      'price': price,
    };
  }
}
