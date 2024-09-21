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
      leaveRoom(roomName, userId);
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

          socket!.on("newBoard", (data) {
            globalRoom = Room.fromJson(data['room']);
            notifyListeners();
          });

          socket!.on("newAlert", (data) async {
            if (data['title'] == "Draw Proposal") {
              showDrawProposalAlertDialog(tempContext, data['title'],
                  data['content'], globalRoom!.roomName, globaluser!.id);
            } else {
              showGameOverAlertDialog(tempContext, data['title'],
                  data['content'], globalRoom!.roomName, globaluser!.id);
            }
          });

          socket!.on("error", (data) async {
            showSnackbar(tempContext, data.toString());
          });

          socket!.on("joined", (data) async {
            String name = data['userName'];
            showSnackbar(context, "$name joined the room");
            if (data['userName'] == globalRoom!.creatorName) {
              globalRoom!.creatorName = name;
            } else {
              globalRoom!.opponentName = name;
            }
            notifyListeners();
          });

          socket!.on("joined-room", (data) {
            globalRoom = Room.fromJson(data['room']);
            globaluser = User.fromJson(data['user']);
            isLoading = false;
            notifyListeners();
          });

          socket!.on("room-created", (data) {
            globalRoom = Room.fromJson(data['room']);
            globaluser = User.fromJson(data['user']);
            isLoading = false;
            notifyListeners();
            navigateToHomePage(context); // Navigate after room creation
          });
        });
      }
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  Future<void> createRoom(String userName, String roomName) async {
    try {
      isLoading = true;
      notifyListeners();
      socket!.emit("create-room", {"roomName": roomName, "userName": userName});
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print("Error creating room: $e");
    }
  }

  Future<void> joinRoom(String userName, String roomName) async {
    try {
      isLoading = true;
      notifyListeners();
      socket!.emit("join-room", {"roomName": roomName, "userName": userName});
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print("Error joining room: $e");
    }
  }

  Future<void> leaveRoom(String roomName, String userId) async {
    try {
      socket!.emit("leave-room", {"roomName": roomName, "userId": userId});
    } catch (e) {
      print("Error leaving room: $e");
    }
  }

  Future<void> sendGameAlert(
      String roomName, String title, String content) async {
    try {
      socket!.emit("game-alert",
          {"roomName": roomName, "title": title, "content": content});
    } catch (e) {
      print("Error sending game alert: $e");
    }
  }

  Future<void> sendUpdatedBoard(BuildContext context, String roomName,
      String newBoard, String color) async {
    try {
      socket!.emit("send-updated-board",
          {"roomName": roomName, "chessBoard": newBoard, "senderColor": color});
    } catch (e) {
      print("Error sending updated board: $e");
    }
  }

  void navigateToHomePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }

  Future<void> disconnectFromSocket(BuildContext context) async {
    try {
      socket!.emit("disconnect");
      await socket!.disconnect();
    } catch (e) {
      print('Error disconnecting from socket: $e');
    }
  }

  Future<void> showAlert(BuildContext context, String title, String content,
      Future<void> Function() onConfirm, bool isGameOver) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !isGameOver,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () async {
                await onConfirm();
                if (isGameOver) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
