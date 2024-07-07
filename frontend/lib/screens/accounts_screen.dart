import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatelessWidget {
  AccountScreen({Key? key}) : super(key: key);

  Future<void> handleLogout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Account'),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.green,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_circle, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text('Owner',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 5),
                  Text('Owner Email',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Menu Section
            Text('My Account',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            // Menu Items
            InkWell(
              onTap: () {
                // Navigate to Payment Methods screen
              },
              child: Row(
                children: [
                  Icon(Icons.credit_card, size: 25),
                  SizedBox(width: 10),
                  Text('Payment Methods', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            SizedBox(height: 15),
            // Add more menu items here
            InkWell(
              onTap: () async {
                // Handle logout
                await handleLogout(context);
              },
              child: Row(
                children: [
                  Icon(Icons.logout, size: 25),
                  SizedBox(width: 10),
                  Text('Logout', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
