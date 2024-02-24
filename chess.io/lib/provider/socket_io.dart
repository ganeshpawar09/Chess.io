import 'package:chess.io/model/room_model.dart';
import 'package:chess.io/model/user_model.dart';
import 'package:chess.io/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketIo extends ChangeNotifier {
  io.Socket? socket;
  Room? globalRoom;
  User? globaluser;
  bool isLoading = false;
  String opponent = "Waiting For Opponent";
  late BuildContext tempContext;

  void showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> showGameOverAlertDialog(BuildContext context, String title,
      String content, String roomName, String userId) async {
    await showAlert(context, title, content, () async {
      leaveFromRoom(context, roomName, userId);
    }, true);
  }

  Future<void> showDrawProposalAlertDialog(BuildContext context, String title,
      String content, String roomName, String userId) async {
    await showAlert(context, title, content, () async {
      try {
        sendGameAlert(roomName, "Game Over",
            "The game has ended in a draw. Both players agreed to a draw.");
        Navigator.pop(context);
      } catch (e) {
        print("Something went wrong while sending alert: $e");
      }
    }, false);
  }

  Future<void> initializeSocket(BuildContext context) async {
    try {
      tempContext = context;
      socket = io.io('https://chess-io.onrender.com', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      if (socket != null) {
        await socket!.connect();

        socket!.onConnect((_) {
          print('Socket connected. ID: ${socket!.id}');
          print('Socket connected successfully.');

          try {
            socket!.on("newBoard", (data) {
              print("newBoard event received: $data");

              globalRoom = Room.fromJson(data['room']);
              if (globalRoom != null) {
                notifyListeners();
              }
            });
          } catch (e) {
            print("Something went wrong while receiving data: $e");
          }

          try {
            socket!.on("newAlert", (data) async {
              if (data['title'] == "Draw Proposal") {
                showDrawProposalAlertDialog(tempContext, data['title'],
                    data['content'], globalRoom!.roomName, globaluser!.id);
              } else {
                showGameOverAlertDialog(tempContext, data['title'],
                    data['content'], globalRoom!.roomName, globaluser!.id);
              }
            });
          } catch (e) {
            print("Something went wrong while showing alert: $e");
          }
          try {
            socket!.on("error", (data) async {
              showSnackbar(tempContext, data.toString());
            });
          } catch (e) {
            print("Something went wrong while showing error: $e");
          }
          try {
            socket!.on("joined", (data) async {
              String name = data['userName'];
              showSnackbar(context, "$name join the room");
              if (data['userName'] == globalRoom!.creatorName) {
                globalRoom!.creatorName = name;
              } else {
                globalRoom!.opponentName = name;
              }
              notifyListeners();
            });
          } catch (e) {
            print("Something went wrong while receiving data: $e");
          }
          try {
            socket!.on("joined-room", (data) {
              print(data);

              globalRoom = Room.fromJson(data['room']);
              globaluser = User.fromJson(data['user']);
              isLoading = false;
              notifyListeners();
            });
          } catch (e) {
            isLoading = false;
            notifyListeners();
            print("Something went wrong while receiving data: $e");
          }
          try {
            socket!.on("room-created", (data) {
              print(data);
              globalRoom = Room.fromJson(data['room']);
              globaluser = User.fromJson(data['user']);
              isLoading = false;
              notifyListeners();
              print('Room Name: ${globalRoom!.roomName}');
              print('User Name: ${globaluser!.userName}');
            });
          } catch (e) {
            isLoading = false;
            notifyListeners();
            print("Something went wrong while receiving data: $e");
          }
        });
      }
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  Future<void> sendGameAlert(
      String roomName, String title, String content) async {
    try {
      socket!.emit("game-alert",
          {"roomName": roomName, "title": title, "content": content});
    } catch (e) {
      print("Error sending new alert: $e");
    }
  }

  Future<void> sendUpdatedBoard(BuildContext context, String roomName,
      String newBoard, String color) async {
    try {
      print(roomName);
      print(newBoard);
      print(color);
      socket!.emit("send-updated-board",
          {"roomName": roomName, "chessBoard": newBoard, "senderColor": color});
    } catch (e) {
      print("Error sending new board: $e");
    }
  }

  Future<void> createRoom(String userName, String roomName) async {
    try {
      isLoading = true;
      notifyListeners();
      print("$userName is joining the room $roomName");

      socket!.emit("create-room", {"roomName": roomName, "userName": userName});
      print("hello");
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print("Error sending new board: $e\nStackTrace: ${e}");
    }
  }

  Future<void> joinRoom(String userName, String roomName) async {
    try {
      isLoading = true;
      notifyListeners();
      print("$userName is join the $roomName");
      socket!.emit("join-room", {"roomName": roomName, "userName": userName});
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print("Error sending new board: $e");
    }
  }

  Future<void> leaveRoom(String roomName, String userId) async {
    try {
      socket!.emit("leave-room", {"roomName": roomName, "userId": userId});
    } catch (e) {
      print("Error sending new alert: $e");
    }
  }

  Future<void> disconnectFromSocket(BuildContext context) async {
    try {
      socket!.emit("disconnect");
      await socket!.disconnect();
    } catch (e) {
      print('Error disconnecting from socket: $e');
    }
  }
}
