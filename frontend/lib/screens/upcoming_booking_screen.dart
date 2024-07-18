import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant.dart';

class BookingItem extends StatelessWidget {
  final dynamic booking;

  BookingItem({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.lightGreen[50],
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 3,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turf Name: ${booking['turfName']}',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(height: 8),
          Text(
            'User Name: ${booking['userName']}',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          SizedBox(height: 8),
          Text(
            'Date: ${DateFormat('MMMM dd, yyyy').format(DateTime.parse(booking['date']))}',
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Time: ',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              Text(
                '${booking['startTime']} - ${booking['endTime']}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Price: ',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              Text(
                '\$${booking['price']}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Remaining Amount: ',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              Text(
                '\$${booking['rem_amount']}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UpcomingBooking extends StatefulWidget {
  @override
  _UpcomingBookingState createState() => _UpcomingBookingState();
}

class _UpcomingBookingState extends State<UpcomingBooking> {
  List<dynamic> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('authToken') ?? '';

    try {
      final turfResponse = await http.get(
        Uri.parse('${Constants.DEVANSH_IP}/api/turf/adminturf'),
        headers: {
          'authToken': authToken,
        },
      );

      final turfData = jsonDecode(turfResponse.body);

      final bookingResponse = await http.get(Uri.parse(
          '${Constants.DEVANSH_IP}/api/booking/getNext5DaysBookings/${turfData['_id']}'));

      setState(() {
        bookings = jsonDecode(bookingResponse.body)['bookings'];
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching bookings: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort the list of bookings based on start time
    bookings.sort((a, b) => a['startTime'].compareTo(b['startTime']));

    // Group bookings by date
    Map<String, List<dynamic>> groupedBookings = {};
    for (var booking in bookings) {
      DateTime startTime = DateTime.parse(booking['date']);
      String date = DateFormat('yyyy-MM-dd').format(startTime);
      if (!groupedBookings.containsKey(date)) {
        groupedBookings[date] = [];
      }
      groupedBookings[date]!.add(booking);
    }

    // Sort the grouped bookings by date
    List<String> sortedDates = groupedBookings.keys.toList();
    sortedDates.sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('Upcoming Bookings'),
        backgroundColor: Colors.green[600], // Green app bar color
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : sortedDates.isEmpty
              ? Center(
                  child: Text('No upcoming bookings',
                      style: TextStyle(fontSize: 18, color: Colors.black)))
              : ListView.builder(
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    String date = sortedDates[index];
                    List<dynamic> bookingsForDate = groupedBookings[date]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          child: Text(
                            DateFormat('MMMM dd, yyyy')
                                .format(DateTime.parse(date)),
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                        ),
                        ...bookingsForDate
                            .map((booking) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: BookingItem(booking: booking),
                                ))
                            .toList(),
                        SizedBox(height: 20), // Add space between dates
                      ],
                    );
                  },
                ),
    );
  }
}
