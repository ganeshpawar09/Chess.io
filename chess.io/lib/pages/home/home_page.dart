import 'package:chess.io/pages/entry/entry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:chess.io/const/colors.dart';
import 'package:chess.io/const/font.dart';
import 'package:chess.io/provider/socket_io.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  ChessBoardController controller = ChessBoardController();
  void contextChange() async {
    if (mounted) {
      Provider.of<SocketIo>(context, listen: false).tempContext = context;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Consumer<SocketIo>(
            builder: (context, value, child) {
              if (value.globalRoom == null || value.globaluser == null) {
                return Center(
                  child: CircularProgressIndicator(color: customYellow),
                );
              } else {
                String userName = value.globaluser!.userName;
                String userId = value.globaluser!.id;
                String userColor = value.globaluser!.lastGameColor;
                String roomName = value.globalRoom!.roomName;
                String opponentName = (value.globaluser!.userName ==
                        value.globalRoom!.creatorName)
                    ? value.globalRoom!.opponentName
                    : value.globalRoom!.creatorName;

                PlayerColor playerColor = (userColor == "white")
                    ? PlayerColor.white
                    : PlayerColor.black;
                bool canMove =
                    (userColor == value.globalRoom!.currentTurn) ? true : false;
                if (controller.getFen() != value.globalRoom!.currentCondition) {
                  controller.loadFen(value.globalRoom!.currentCondition);
                }
                return PopScope(
                  canPop: false,
                  onPopInvoked: (bool didpop) async {
                    showResignDialog(context, roomName, userId);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Chess",
                                    style: AppStyles.mondaB.copyWith(
                                        fontSize: 28,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: ".io",
                                    style: AppStyles.mondaB.copyWith(
                                      fontSize: 28,
                                      color: customYellow,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                    onPressed: () {
                                      showResignDialog(
                                          context, roomName, userId);
                                    },
                                    child: Text("Resign",
                                        style: AppStyles.mondaN.copyWith(
                                            fontSize: 16,
                                            color: Colors.white))),
                                TextButton(
                                    onPressed: () {
                                      showDrawDialog(context, roomName);
                                    },
                                    child: Text("Draw",
                                        style: AppStyles.mondaN.copyWith(
                                            fontSize: 16,
                                            color: Colors.white))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      customNamePlate(opponentName),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        height: 360,
                        width: double.infinity,
                        child: Center(
                          child: ChessBoard(
                            controller: controller,
                            onMove: () {
                              if (value.globalRoom!.currentCondition !=
                                  controller.getFen()) {
                                nextMove(
                                    roomName, controller.getFen(), userColor);
                              }
                            },
                            enableUserMoves: canMove,
                            boardColor: BoardColor.orange,
                            boardOrientation: playerColor,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      customNamePlate(userName),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void nextMove(String roomName, String newBoard, String senderColor) async {
    try {
      await Provider.of<SocketIo>(context, listen: false)
          .sendUpdatedBoard(context, roomName, newBoard, senderColor);
    } catch (e) {
      print('Error sending updated board: $e');
    }
    if (controller.isCheckMate()) {
      sendNewAlertToSocket(roomName, "Game Over",
          "$senderColor has won the game with a Checkmate!");
    } else if (controller.isDraw()) {
      sendNewAlertToSocket(roomName, "Game Over", "The game ended in a draw.");
    } else if (controller.isStaleMate()) {
      sendNewAlertToSocket(
          roomName, "Game Over", "The game ended in a stalemate.");
    } else if (controller.isThreefoldRepetition()) {
      sendNewAlertToSocket(
        roomName,
        "Game Over",
        "The game ended in a draw due to threefold repetition.",
      );
    } else if (controller.isInsufficientMaterial()) {
       sendNewAlertToSocket(
        roomName,
        "Game Over",
        "The game ended in a draw due to insufficient material.",
      );
    }
  }

  void sendNewAlertToSocket(
      String roomName, String title, String content) async {
    try {
      await Provider.of<SocketIo>(context, listen: false)
          .sendGameAlert(roomName, title, content);
    } catch (e) {
      print("Something went wrong while sending alert: $e");
    }
  }

  Future<void> showResignDialog(
      BuildContext context, String roomName, String userId) async {
    await showAlert(context, "Resign", "Are you sure?", () async {
      sendNewAlertToSocket(roomName, "Game Over",
          "Your opponent has resigned. You are the winner!");
      leaveFromRoom(context, roomName, userId);
    }, false);
  }

  Future<void> showDrawDialog(BuildContext context, String roomName) async {
    await showAlert(
      context,
      "Draw",
      "Are you sure you want to propose a draw?",
      () async {
        sendNewAlertToSocket(
          roomName,
          "Draw Proposal",
          "Do you agree to a draw?",
        );
        Navigator.pop(context);
      },
      false,
    );
  }
}

void leaveFromRoom(BuildContext context, String roomName, String userId) async {
  try {
    Provider.of<SocketIo>(context, listen: false).globaluser = null;
    Provider.of<SocketIo>(context, listen: false).globalRoom = null;
    Provider.of<SocketIo>(context, listen: false).isLoading = false;
    Provider.of<SocketIo>(context, listen: false).opponent =
        "Waiting for Opponent";

    await Provider.of<SocketIo>(context, listen: false)
        .leaveRoom(roomName, userId);
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) =>const EntryPage()),
        (route) => false, // This will remove all routes from the stack
      );
    }
  } catch (error) {
    print("Error leaving room: $error");
    // You can also show a custom snackbar or handle the error in another way.
  }
}

Future<void> showAlert(BuildContext context, String title, String content,
    Function onYesPressed, bool gameOver) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(
        title,
        style: AppStyles.mondaN.copyWith(fontSize: 20, color: Colors.white),
      ),
      content: Text(
        content,
        style: AppStyles.mondaN.copyWith(fontSize: 15, color: Colors.white),
      ),
      actions: (gameOver)
          ? [
              TextButton(
                onPressed: () async {
                  onYesPressed();
                },
                child: Text(
                  'Leave Room',
                  style: AppStyles.mondaN
                      .copyWith(fontSize: 15, color: customYellow),
                ),
              ),
            ]
          : [
              TextButton(
                onPressed: () async {
                  onYesPressed();
                },
                child: Text(
                  'Yes',
                  style: AppStyles.mondaN
                      .copyWith(fontSize: 15, color: customYellow),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'No',
                  style: AppStyles.mondaN
                      .copyWith(fontSize: 15, color: customYellow),
                ),
              ),
            ],
    ),
  );
}

Widget customNamePlate(
  String name,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Row(
      children: [
        Image.asset(
          fit: BoxFit.cover,
          "assets/avatar.png",
          width: 40,
          height: 40,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          name,
          style: AppStyles.mondaN.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        )
      ],
    ),
  );
}
