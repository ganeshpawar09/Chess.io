class User {
  String userName;
  String socketId;
  String lastRoomName;
  String lastGameColor;
  String id;

  User({
    required this.userName,
    required this.socketId,
    required this.lastRoomName,
    required this.lastGameColor,
    required this.id,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userName: json['userName'] ?? '',
      socketId: json['socketId'] ?? '',
      lastRoomName: json['lastRoomName'] ?? '',
      lastGameColor: json['lastGameColor'] ?? '',
      id: json['_id'] ?? '',
    );
  }
}