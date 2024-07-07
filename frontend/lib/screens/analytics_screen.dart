import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const DEVANSH_IP = '192.168.1.3'; // Replace with your actual IP address

class Analytics extends StatefulWidget {
  @override
  _AnalyticsState createState() => _AnalyticsState();
}

class _AnalyticsState extends State<Analytics> {
  dynamic turf;
  dynamic analytics;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';

    try {
      final turfResponse = await http.get(
        Uri.parse('http://localhost:5000/api/turf/adminturf'),
        headers: {
          'authToken': authToken,
        },
      );

      final turfData = jsonDecode(turfResponse.body);

      final analyticsResponse = await http.get(Uri.parse(
          'http://localhost:5000/api/turf/getTurfAnalytics/${turfData['_id']}'));

      setState(() {
        turf = turfData;
        analytics = jsonDecode(analyticsResponse.body);
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching analytics: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics'),
        backgroundColor: Colors.green[600],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Overall Performance'),
                  buildAnalyticsCard(
                    context,
                    'Overall Earnings',
                    '₹${analytics['overallEarnings']}',
                    titleStyle: TextStyle(fontSize: 18, color: Colors.black87),
                    valueStyle: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700]),
                    icon: Icons.monetization_on,
                  ),
                  SizedBox(height: 20),
                  buildSectionTitle('Top Performers'),
                  Row(
                    children: [
                      Expanded(
                        child: buildAnalyticsCard(
                          context,
                          'Highest Earning Day',
                          analytics['highestEarningDay'],
                          icon: Icons.calendar_today,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: buildAnalyticsCard(
                          context,
                          'Highest Earning Month',
                          analytics['highestEarningMonth'],
                          icon: Icons.calendar_view_month,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  buildAnalyticsCard(
                    context,
                    'Top User',
                    analytics['topUser'],
                    icon: Icons.person,
                  ),
                  SizedBox(height: 20),
                  buildAnalyticsCard(
                    context,
                    'Busiest Day of the Week',
                    analytics['topDayOfWeek'],
                    icon: Icons.event_busy,
                  ),
                  SizedBox(height: 20),
                  buildSectionTitle('Booking Details'),
                  buildAnalyticsCard(
                    context,
                    'Average Booking Duration',
                    '${analytics['averageBookingDuration']} minutes',
                    icon: Icons.access_time,
                  ),
                  SizedBox(height: 20),
                  buildAnalyticsCard(
                    context,
                    'Average Earnings Per Booking',
                    '₹${analytics['averageEarningsPerBooking']}',
                    icon: Icons.attach_money,
                  ),
                  SizedBox(height: 20),
                  buildAnalyticsCard(
                    context,
                    'Percentage of Slots Booked',
                    '${analytics['percentageSlotsBooked'].toStringAsFixed(2)}%',
                    icon: Icons.timeline,
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildAnalyticsCard(
    BuildContext context,
    String title,
    String value, {
    TextStyle? titleStyle,
    TextStyle? valueStyle,
    IconData? icon,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 30,
              color: Colors.green[700],
            ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: titleStyle ??
                      TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                ),
                SizedBox(height: 5),
                Text(
                  value,
                  style: valueStyle ??
                      TextStyle(fontSize: 22, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.green[700],
        ),
      ),
    );
  }
}
