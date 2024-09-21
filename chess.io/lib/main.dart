import 'package:chess.io/const/colors.dart';
import 'package:chess.io/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:chess.io/provider/socket_io.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const Chess());
}

final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

class Chess extends StatelessWidget {
  const Chess({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SocketIo(),
        )
      ],
      child: MaterialApp(
        key: scaffoldKey,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData.dark().copyWith(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: customYellow),
          scaffoldBackgroundColor: Colors.grey[900],
          appBarTheme: AppBarTheme(
              scrolledUnderElevation: 0.0, backgroundColor: Colors.grey[900]),
        ),
        home: HomePage(),
      ),
    );
  }
}
