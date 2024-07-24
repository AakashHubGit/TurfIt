import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/booking_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';
import '../constant.dart';

class JoinBookingPage extends StatefulWidget {
  @override
  _JoinBookingPageState createState() => _JoinBookingPageState();
}

class _JoinBookingPageState extends State<JoinBookingPage> {
  List<Booking> bookings = [];
  bool loading = true;
  late AuthModel authModel;

  @override
  void initState() {
    super.initState();
    fetchAuthToken();
  }

  Future<void> fetchAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('authToken');
    if (authToken == null) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Authentication token not found. Please log in.')),
      );
    } else {
      authModel = AuthModel(
          id: 1, authToken: authToken); // Replace with actual user details
      fetchBookings();
    }
  }

  Future<void> fetchBookings() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.DEVANSH_IP}/api/booking/requested'),
        headers: {'authToken': authModel.authToken},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          bookings = data.map((json) => Booking.fromJson(json)).toList();
          loading = false;
        });
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (error) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bookings: $error')),
      );
    }
  }

  Future<void> joinBooking(String bookingId, int playersCount) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.DEVANSH_IP}/api/booking/joinbooking'),
        headers: {
          'authToken': authModel.authToken,
          'Content-Type': 'application/json',
        },
        body:
            jsonEncode({'bookingId': bookingId, 'playersCount': playersCount}),
      );
      if (response.statusCode == 200) {
        fetchBookings(); // Refresh bookings after joining
      } else {
        throw Exception('Failed to join booking');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining booking: $error')),
      );
    }
  }

  void showPlayerSelectionDialog(BuildContext context, Booking booking) {
    int selectedPlayers = 1; // Default selection
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Number of Players'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<int>(
                value: selectedPlayers,
                items: List.generate(booking.requestedPlayers, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    selectedPlayers = value!;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                joinBooking(booking.id, selectedPlayers);
              },
              child: Text('Join'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Bookings')),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return ListTile(
                  title: Text('Turf: ${booking.turfId}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Name: ${booking.joinedPlayers.isNotEmpty ? booking.joinedPlayers[0].userName : 'N/A'}'),
                      Text(
                          'Date: ${booking.date.toLocal().toString().split(' ')[0]}'),
                      Text(
                          'Time Slot: ${booking.startTime} - ${booking.endTime}'),
                      Text(
                          'Requested Players: ${booking.requestedPlayers}, Total Players: ${booking.totalPlayers}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      showPlayerSelectionDialog(context, booking);
                    },
                    child: Text('Join'),
                  ),
                );
              },
            ),
    );
  }
}
