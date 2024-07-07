import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turf_it/screens/admin_dashboard_screen.dart';
import 'package:turf_it/screens/upcoming_booking_screen.dart';
import 'package:turf_it/screens/analytics_screen.dart';
import 'package:turf_it/screens/accounts_screen.dart';

const DEVANSH_IP = '192.168.1.3'; // Replace with your actual IP address

class BottomNavBarDemo extends StatefulWidget {
  @override
  _BottomNavBarDemoState createState() => _BottomNavBarDemoState();
}

class _BottomNavBarDemoState extends State<BottomNavBarDemo> {
  int _selectedIndex = 0;
  dynamic adminData;
  dynamic turfData;
  dynamic bookingData;
  dynamic analyticsData;
  late Future<void> _fetchDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = fetchAdminTurfAndBooking();
  }

  Future<void> fetchAdminTurfAndBooking() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';
    try {
      final adminResponse = await http.get(
        Uri.parse('http://localhost:5000/api/auth/getadmin'),
        headers: {
          'authToken': authToken,
        },
      );
      final turfResponse = await http.get(
        Uri.parse('http://localhost:5000/api/turf/adminturf'),
        headers: {
          'authToken': authToken,
        },
      );

      setState(() {
        adminData = jsonDecode(adminResponse.body);
        turfData = [jsonDecode(turfResponse.body)];
      });

      // Get bookings for the turf
      final bookingResponse = await http.get(Uri.parse(
          'http://localhost:5000/api/booking/getNext5DaysBookings/${turfData[0]['_id']}'));

      final analyticsResponse = await http.get(Uri.parse(
          'http://localhost:5000/api/turf/getTurfAnalytics/${turfData[0]['_id']}'));
      setState(() {
        bookingData = jsonDecode(bookingResponse.body)['bookings'];
        analyticsData = jsonDecode(analyticsResponse.body);
      });
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  Future<void> _refreshData() async {
    await fetchAdminTurfAndBooking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<void>(
          future: _fetchDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return _selectedIndex == 0
                  ? AdminDashboardScreen()
                  : _widgetOptions().elementAt(_selectedIndex - 1);
            }
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // Set background color
        selectedItemColor: Colors.lightBlue, // Set selected item color
        unselectedItemColor: Colors.grey, // Set unselected item color
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 8, // Add elevation for a shadow effect
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _widgetOptions() => <Widget>[
        UpcomingBooking(bookings: bookingData),
        Analytics(
            turf: turfData, analytics: analyticsData), // Pass analyticsData
        AccountScreen(),
      ];
}
