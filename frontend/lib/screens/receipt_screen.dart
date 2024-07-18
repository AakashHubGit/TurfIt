import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constant.dart';

class ReceiptPage extends StatefulWidget {
  @override
  _ReceiptPageState createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  late Map booking;
  late String user;
  String userName = "";
  String turfName = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Map arguments = ModalRoute.of(context)!.settings.arguments as Map;
    booking = arguments['booking'];
    user = arguments['user'];
    fetchUserDetails(booking['user']);
    fetchTurfName(booking['turf']);
  }

  void fetchUserDetails(String userId) async {
    try {
      final response = await http.get(
        Uri.parse(
          user == "Owner"
              ? '${Constants.DEVANSH_IP}/api/auth/getoffuser/$userId'
              : '${Constants.DEVANSH_IP}/api/auth/getuser/$userId',
        ),
      );
      final data = json.decode(response.body);
      setState(() {
        userName = data['name'];
      });
    } catch (error) {
      print("Error fetching user details: $error");
    }
  }

  void fetchTurfName(String turfId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.DEVANSH_IP}/api/turf/getturf/$turfId'),
      );
      final data = json.decode(response.body);
      setState(() {
        turfName = data['name'];
      });
    } catch (error) {
      print("Error fetching turf name: $error");
    }
  }

  String formatDate(String dateString) {
    final DateTime date = DateTime.parse(dateString);
    return DateFormat('MMMM d, yyyy').format(date);
  }

  String convertTo12HourFormat(String time) {
    final int hour = int.parse(time.split(':')[0]);
    if (hour == 0) return '12 am';
    if (hour == 12) return '12 pm';
    if (hour < 12) return '$hour am';
    return '${hour - 12} pm';
  }

  String formatPrice(int price) {
    return '₹$price';
  }

  void navigateToHome() {
    if (user == "Owner") {
      Navigator.pushNamedAndRemoveUntil(
          context, '/adminDashboard', (Route<dynamic> route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(
          context, '/home', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8FF),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white, // Changed background color
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.3), // Changed shadow color and opacity
                offset: Offset(0, 2), // Increased shadow offset
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Booking Receipt',
                style: TextStyle(
                  fontSize: 28, // Increased font size
                  fontWeight: FontWeight.bold,
                  color: Colors.green, // Changed text color
                ),
              ),
              SizedBox(height: 20),
              buildInfoRow('Turf Name:', turfName),
              buildInfoRow('User Name:', userName),
              buildInfoRow('Date:', formatDate(booking['date'])),
              buildInfoRow(
                  'Start Time:', convertTo12HourFormat(booking['startTime'])),
              buildInfoRow(
                  'End Time:', convertTo12HourFormat(booking['endTime'])),
              buildInfoRow('Price:', formatPrice(booking['price'])),
              SizedBox(height: 30), // Increased spacing
              ElevatedButton(
                onPressed: navigateToHome,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                      vertical: 16, horizontal: 24), // Increased button padding
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8), // Increased border radius
                  ),
                ),
                child: Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 18, // Increased font size
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
              fontSize: 18, // Increased font size
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
                fontSize: 18, // Increased font size
              ),
            ),
          ),
        ],
      ),
    );
  }
}
