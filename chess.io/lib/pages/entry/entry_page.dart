
import 'package:chess.io/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:chess.io/const/colors.dart';
import 'package:chess.io/const/font.dart';
import 'package:chess.io/provider/socket_io.dart';
import 'package:provider/provider.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _roomName = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void showCustomSnackBar(BuildContext context, String data) {
    SnackBar snackBar = SnackBar(content: Text(data));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void socketInit() async {
    if (mounted) {
      await Provider.of<SocketIo>(context, listen: false)
          .initializeSocket(context);
    }
  }

  void socketDispose() async {
    if (mounted) {
      await Provider.of<SocketIo>(context, listen: false)
          .disconnectFromSocket(context);
    }
  }

  void createRoomSocket() async {
    try {
      String name = _name.text.toString();
      String roomName = _roomName.text.toString();

      if (name.isEmpty || roomName.isEmpty) {
        showCustomSnackBar(context, "Name or Room Name is empty");
      } else {
        if (mounted) {
          await Provider.of<SocketIo>(context, listen: false)
              .createRoom(name, roomName);
        }
      }
    } catch (e) {
      print("Something went wrong while creating room");
    }
  }

  void joinRoomSocket() async {
    try {
      String name = _name.text.toString();
      String roomName = _roomName.text.toString();

      if (name.isEmpty || roomName.isEmpty) {
        showCustomSnackBar(context, "Name or Room Name is empty");
      } else {
        if (mounted) {
          await Provider.of<SocketIo>(context, listen: false)
              .joinRoom(name, roomName);
        }
      }
    } catch (e) {
      print("Something went wrong while creating room");
    }
  }

  void next() {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } catch (error) {
      print("Error: $error");
      showCustomSnackBar(context, "Something went wrong");
    }
  }

  @override
  void initState() {
    super.initState();
    socketInit();
    socketDispose();

    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
      Image.asset(
        "assets/chess.jpg",
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            elevation: 5,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey[900],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Chess",
                          style: AppStyles.mondaB.copyWith(
                              fontSize: 30,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: ".io",
                          style: AppStyles.mondaB.copyWith(
                            fontSize: 30,
                            color: customYellow,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  customTextField(_name, "Enter your Name"),
                  const SizedBox(
                    height: 5,
                  ),
                  customTextField(_roomName, "Enter Room Name"),
                  const SizedBox(
                    height: 10,
                  ),
                  Consumer<SocketIo>(
                    builder: (context, value, child) {
                      if (value.isLoading == true) {
                        return const SizedBox(
                          height: 100,
                          child: Center(
                            child:
                                CircularProgressIndicator(color: Colors.black),
                          ),
                        );
                      } else if (value.globalRoom == null &&
                          value.globaluser == null) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: customYellow,
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        minimumSize: const Size(200, 40)),
                                    onPressed: () {
                                      _focusNode.unfocus();
                                      createRoomSocket();
                                    },
                                    child: Center(
                                      child: Text(
                                        "Create \nRoom",
                                        textAlign: TextAlign.center,
                                        style: AppStyles.mondaB.copyWith(
                                          color: Colors.black,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: customYellow,
                                        side: BorderSide.none,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        minimumSize: const Size(200, 40)),
                                    onPressed: () {
                                      _focusNode.unfocus();
                                      joinRoomSocket();
                                    },
                                    child: Center(
                                      child: Text(
                                        "Join \nRoom",
                                        textAlign: TextAlign.center,
                                        style: AppStyles.mondaB.copyWith(
                                          color: Colors.black,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: customYellow,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5)),
                                  minimumSize: const Size(200, 40)),
                              onPressed: () {
                                next();
                              },
                              child: Text(
                                "Play Now",
                                style: AppStyles.mondaB.copyWith(
                                  color: Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 30,
                            )
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ]));
  }

  Widget customTextField(TextEditingController controller, String title) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.text,
      cursorColor: Colors.white,
      style: AppStyles.mondaB.copyWith(
        color: Colors.white,
        fontSize: 17,
      ),
      decoration: InputDecoration(
          hintText: title,
          counter: const SizedBox(
            height: 0,
            width: 0,
          ),
          hintStyle: AppStyles.mondaB.copyWith(
              color: Colors.white70, fontSize: 17, fontWeight: FontWeight.bold),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(width: 2, color: customYellow)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(width: 1, color: Colors.white)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20)),
    );
  }
}
