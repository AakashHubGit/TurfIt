import 'package:flutter/material.dart';
import 'package:turf_it/screens/admin_dashboard_screen.dart';
import 'package:turf_it/user_screens/user_home_screen.dart';
import 'screens/login_screen.dart'; // Import the login screen file
import 'screens/slot_booking_screen.dart';
import 'screens/receipt_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => LoginScreen(),
        '/adminDashboard': (context) => AdminDashboardScreen(),
        '/home': (context) => HomeScreen(),
        '/slotBooking': (context) => TurfSlots(),
        '/receiptPage': (context) => ReceiptPage(),
      },
    );
  }
}
