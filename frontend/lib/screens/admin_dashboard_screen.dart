import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:turf_it/screens/slot_booking_screen.dart';
import 'package:turf_it/screens/upcoming_booking_screen.dart';
import 'package:turf_it/screens/analytics_screen.dart';
import 'package:turf_it/screens/accounts_screen.dart';
import 'package:turf_it/screens/payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const DEVANSH_IP = '192.168.1.3'; // Replace with your actual IP address

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  dynamic admin = {};
  List<dynamic> turfs = [];
  double totalEarnings = 0;
  double receivedAmount = 0;
  double remainingPayment = 0;
  List<dynamic> todaysBookings = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('authToken') ?? '';
      // Fetch admin details
      final adminResponse = await http.get(
        Uri.parse('http://localhost:5000/api/auth/getadmin'),
        headers: {
          'authToken': authToken,
        },
      );
      final adminData = jsonDecode(adminResponse.body);

      // Fetch turf details
      final turfResponse = await http.get(
        Uri.parse('http://localhost:5000/api/turf/adminturf'),
        headers: {
          'authToken': authToken,
        },
      );
      final List<dynamic> turfData = jsonDecode(turfResponse.body) is List
          ? jsonDecode(turfResponse.body)
          : [jsonDecode(turfResponse.body)];

      // Update state with fetched data
      setState(() {
        admin = adminData;
        turfs = turfData;
      });

      // Fetch today's bookings after turfs data is available
      fetchTodaysBookings();
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  Future<void> fetchTodaysBookings() async {
    try {
      String formattedDate = DateTime.now().toString().substring(0, 10);
      List<dynamic> allBookings = [];
      for (var turf in turfs) {
        final response = await http.get(Uri.parse(
            'http://localhost:5000/api/booking/today/${turf['_id']}/$formattedDate'));
        final List<dynamic> fetchedBookings = jsonDecode(response.body);
        allBookings.addAll(fetchedBookings);
      }
      setState(() {
        todaysBookings = allBookings;
      });
      calculateEarnings(todaysBookings);
    } catch (error) {
      print('Error fetching bookings: $error');
    }
  }

  void calculateEarnings(List<dynamic> bookings) {
    double total = 0;
    double received = 0;
    double remaining = 0;
    bookings.forEach((booking) {
      total += booking['price'];
      received += booking['price'] - booking['rem_amount'];
      remaining += booking['rem_amount'];
    });

    setState(() {
      totalEarnings = total;
      receivedAmount = received;
      remainingPayment = remaining;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        physics:
            AlwaysScrollableScrollPhysics(), // Allow scrolling when list is small
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome,',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    admin['name'] ?? '',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpcomingBooking(),
                      ),
                    );
                  },
                  child: Text('Notifications'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Analytics(),
                      ),
                    );
                  },
                  child: Text('Analytics'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AccountScreen(),
                      ),
                    );
                  },
                  child: Text('Accounts'),
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: turfs.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return renderDashboard();
                }
                dynamic item = turfs[index - 1];
                return TurfCard(
                  turf: item,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget renderDashboard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[200], // Green background color
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Black shadow color
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // Changes the position of the shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, color: Colors.black), // Dashboard icon
              SizedBox(width: 8),
              Text(
                'Dashboard',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black), // Text color
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Today\'s Earnings',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black), // Text color
          ),
          SizedBox(height: 8),
          Text(
            '₹$totalEarnings',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black), // Text color
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Blob(
                  text1: 'Received',
                  text2: '₹$receivedAmount',
                  icon: Icons.attach_money_rounded), // Payment icon
              Blob(
                  text1: 'Remaining',
                  text2: '₹$remainingPayment',
                  icon: Icons.money_off_rounded), // Payment icon
            ],
          ),
        ],
      ),
    );
  }
}

class Blob extends StatelessWidget {
  final String text1;
  final String text2;
  final IconData icon;

  Blob({required this.text1, required this.text2, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[100], // Green background color
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Black shadow color
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // Changes the position of the shadow
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black), // Icon
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text1,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black), // Text color
              ),
              Text(
                text2,
                style: TextStyle(color: Colors.black), // Text color
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TurfCard extends StatefulWidget {
  final dynamic turf;

  TurfCard({required this.turf});

  @override
  _TurfCardState createState() => _TurfCardState();
}

class _TurfCardState extends State<TurfCard> {
  List<dynamic> bookings = [];

  @override
  void initState() {
    super.initState();
    fetchTurfBookings();
  }

  Future<void> fetchTurfBookings() async {
    try {
      String formattedDate = DateTime.now().toString().substring(0, 10);
      final response = await http.get(Uri.parse(
          'http://localhost:5000/api/booking/today/${widget.turf['_id']}/$formattedDate'));
      final List<dynamic> fetchedBookings = jsonDecode(response.body);

      fetchedBookings.sort((a, b) => a['startTime'].compareTo(b['startTime']));

      setState(() {
        bookings = fetchedBookings;
      });
    } catch (error) {
      print('Error fetching bookings: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[100], // Green background color
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Black shadow color
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // Changes the position of the shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.turf['name'],
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Roboto'), // Text color and font family
          ),
          SizedBox(height: 8),
          Text('Size: ${widget.turf['size'][0]}',
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Roboto')), // Text color and font family
          Text('Rate: ₹${widget.turf['rate']} per hour',
              style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Roboto')), // Text color and font family
          Text(
            'Booking Hours: ${widget.turf['booking_start']} to ${widget.turf['booking_end']}',
            style: TextStyle(
                color: Colors.black,
                fontFamily: 'Roboto'), // Text color and font family
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Bookings:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily:
                          'Roboto'), // Text color, font family, and bold font weight
                ),
                SizedBox(height: 8),
                bookings.isNotEmpty
                    ? Column(
                        children: bookings.map((booking) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PaymentScreen(booking: booking),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '${booking['userName']} - ${booking['startTime']} to ${booking['endTime']}',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontFamily:
                                            'Roboto')), // Text color and font family
                                booking['rem_amount'] == 0
                                    ? Icon(Icons.check_circle_outline,
                                        color: Colors.green)
                                    : Icon(Icons.cancel_outlined,
                                        color: Colors.red),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    : Text('No bookings for today',
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Roboto')), // Text color, font family
              ],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TurfSlots(turf: widget.turf)));
            },
            child: Text('Book Now',
                style: TextStyle(fontFamily: 'Roboto')), // Font family
          ),
        ],
      ),
    );
  }
}
