import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../constant.dart';

const DEVANSH_IP = '192.168.1.3';

class PaymentScreen extends StatelessWidget {
  final dynamic booking;

  PaymentScreen({required this.booking});

  Future<void> handlePaymentApproval(BuildContext context) async {
    try {
      final response = await http.put(
        Uri.parse('${Constants.DEVANSH_IP}/api/booking/${booking['_id']}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{'rem_amount': 0}),
      );

      if (response.statusCode == 200) {
        // Show a success message or navigate to a success screen
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Payment Approved"),
              content: Text("The payment has been successfully approved."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to AdminDashboard
                    Navigator.pushNamedAndRemoveUntil(context,
                        '/adminDashboard', (Route<dynamic> route) => false);
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        // Show an error message
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Error"),
              content:
                  Text("Failed to approve payment. Please try again later."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (error) {
      print("Error approving payment: $error");
      // Show an error message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content:
                Text("An unexpected error occurred. Please try again later."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Widget getTimeSlotIcon() {
    DateTime startTime = DateFormat("HH:mm").parse(booking['startTime']);
    if (startTime.hour >= 6 && startTime.hour < 18) {
      return Icon(Icons.wb_sunny, color: Colors.orange, size: 40);
    } else {
      return Icon(Icons.nightlight_round, color: Colors.blue, size: 40);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Booking Details"),
        // Back button
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.green[600],
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            getTimeSlotIcon(),
            SizedBox(height: 20),
            Text("User:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("${booking['userName']}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text("Time:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("${booking['startTime']} to ${booking['endTime']}",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text("Amount:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("₹${booking['rem_amount']}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text("Payment Status:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                booking['rem_amount'] == 0
                    ? Icon(Icons.check_circle, color: Colors.green, size: 30)
                    : Icon(Icons.cancel, color: Colors.red, size: 30),
                SizedBox(width: 10),
                Text(
                  booking['rem_amount'] == 0 ? 'Paid' : 'Not Paid',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        booking['rem_amount'] == 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text("Scan QR Code to Pay:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child:
                    Image.asset("assets/qrcode.png", width: 200, height: 200),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => handlePaymentApproval(context),
              child: Text("Approve Payment", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
