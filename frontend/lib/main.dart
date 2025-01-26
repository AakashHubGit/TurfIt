import 'package:flutter/material.dart';
import 'package:frontend/user_screens/user_home_screen.dart';
import 'user_screens/login_screen.dart';
import 'user_screens/reg_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/registration': (context) => RegistrationScreen()
      },
    );
  }
}
