class Room {
  String roomName;
  String creatorName;
  String opponentName;
  int roomSize;
  String currentCondition;
  String currentTurn;
  bool gameIsOver;
  String id;

  Room({
    required this.roomName,
    required this.creatorName,
    required this.opponentName,
    required this.roomSize,
    required this.currentCondition,
    required this.currentTurn,
    required this.gameIsOver,
    required this.id,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      roomName: json['roomName'] ?? '',
      creatorName: json['creatorName'] ?? '',
      opponentName: json['opponentName'] ?? '',
      roomSize: json['roomSize'] as int? ?? 0,
      currentCondition: json['currentCondition'] ?? '',
      currentTurn: json['currentTurn'] ?? '',
      gameIsOver: json['gameIsOver'] as bool? ?? false,
      id: json['_id'] ?? '',
    );
  }
}
