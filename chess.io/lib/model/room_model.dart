class Room {
  String roomName;
  String creatorName;
  String opponentName;
  String currentCondition;
  String currentTurn;
  bool gameIsOver;
  String id;

  Room({
    required this.roomName,
    required this.creatorName,
    required this.opponentName,
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
      currentCondition: json['currentCondition'] ?? '',
      currentTurn: json['currentTurn'] ?? '',
      gameIsOver: json['gameIsOver'] as bool? ?? false,
      id: json['_id'] ?? '',
    );
  }
}
