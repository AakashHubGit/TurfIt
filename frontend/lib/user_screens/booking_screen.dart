import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/user_screens/user_home_screen.dart';
import '../models/auth_model.dart';
import '../models/slot_model.dart';
import '../constant.dart';

class SlotBookingScreen extends StatefulWidget {
  final String turfId;
  final String adminId;

  SlotBookingScreen({required this.turfId, required this.adminId});

  @override
  _SlotBookingScreenState createState() => _SlotBookingScreenState();
}

class _SlotBookingScreenState extends State<SlotBookingScreen> {
  List<Slot> slots = [];
  DateTime date = DateTime.now();
  DateTime utcBookingDate = DateTime.now().toUtc();
  Slot? startSlot;
  Slot? endSlot;
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
      showErrorDialog('Authentication failed. Please log in again.');
    } else {
      authModel = AuthModel(id: 1, authToken: authToken);
      fetchSlots();
    }
  }

  Future<void> fetchSlots() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Constants.DEVANSH_IP}/api/turf/${widget.turfId}/slots?date=${DateFormat('yyyy-MM-dd').format(date)}'),
        headers: {'Authorization': 'Bearer ${authModel.authToken}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          slots = (data['data']['slots'] as List)
              .map((slot) => Slot.fromJson(slot))
              .toList();
          loading = false;
        });
        fetchBookedSlots();
      } else {
        throw Exception('Failed to fetch slots: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error fetching slots: $error');
      showErrorDialog('Failed to fetch slot data. Please try again later.');
    }
  }

  Future<void> fetchBookedSlots() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Constants.DEVANSH_IP}/api/booking/${widget.turfId}/booked-slots?date=${DateFormat('yyyy-MM-dd').format(date)}'),
        headers: {'Authorization': 'Bearer ${authModel.authToken}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bookedSlotsData = (data['data']['bookedSlots'] as List)
            .map((slot) => Slot.fromJson(slot))
            .toList();

        setState(() {
          slots = slots.map((slot) {
            if (bookedSlotsData.any((bookedSlot) => isTimeOverlapping(
                slot.startTime,
                slot.endTime,
                bookedSlot.startTime,
                bookedSlot.endTime))) {
              slot.isBooked = true;
            }
            return slot;
          }).toList();
        });
      } else {
        throw Exception(
            'Failed to fetch booked slots: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error fetching booked slots: $error');
      showErrorDialog(
          'Failed to fetch booked slot data. Please try again later.');
    }
  }

  bool isTimeOverlapping(
      String start1, String end1, String start2, String end2) {
    final startTime1 = DateFormat.Hm().parse(start1);
    final endTime1 = DateFormat.Hm().parse(end1);
    final startTime2 = DateFormat.Hm().parse(start2);
    final endTime2 = DateFormat.Hm().parse(end2);

    return startTime1.isBefore(endTime2) && endTime1.isAfter(startTime2);
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void handleDateChange(DateTime selectedDate) {
    setState(() {
      date = selectedDate;
      utcBookingDate = selectedDate.toUtc();
      loading = true;
      fetchSlots();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != date) handleDateChange(picked);
  }

  void handleSlotSelection(Slot slot) {
    if (slot.isBooked) return;

    setState(() {
      if (startSlot == null || endSlot == null) {
        startSlot = slot;
        endSlot = slot;
      } else {
        final slotStartTime = DateFormat.Hm().parse(slot.startTime);
        final slotEndTime = DateFormat.Hm().parse(slot.endTime);
        final startSlotTime = DateFormat.Hm().parse(startSlot!.startTime);
        final endSlotTime = DateFormat.Hm().parse(endSlot!.endTime);

        if (slotStartTime.isAtSameMomentAs(endSlotTime)) {
          endSlot = slot;
        } else if (slotEndTime.isAtSameMomentAs(startSlotTime)) {
          startSlot = slot;
        } else {
          startSlot = slot;
          endSlot = slot;
        }
      }
    });
  }

  bool isSlotInRange(Slot slot) {
    if (startSlot == null || endSlot == null) return false;

    final slotStartTime = DateFormat.Hm().parse(slot.startTime);
    final slotEndTime = DateFormat.Hm().parse(slot.endTime);
    final startSlotTime = DateFormat.Hm().parse(startSlot!.startTime);
    final endSlotTime = DateFormat.Hm().parse(endSlot!.endTime);

    if (startSlotTime.isBefore(endSlotTime)) {
      return slotStartTime.isAtSameMomentAs(startSlotTime) ||
          slotEndTime.isAtSameMomentAs(endSlotTime) ||
          (slotStartTime.isAfter(startSlotTime) &&
              slotEndTime.isBefore(endSlotTime));
    } else {
      return slotStartTime.isAtSameMomentAs(endSlotTime) ||
          slotEndTime.isAtSameMomentAs(startSlotTime) ||
          (slotStartTime.isAfter(endSlotTime) &&
              slotEndTime.isBefore(startSlotTime));
    }
  }

  Future<void> handleBooking() async {
    try {
      if (startSlot == null || endSlot == null) {
        showErrorDialog('Please select continuous slots.');
        return;
      }

      List<String> timeSlots =
          _generateTimeSlots(startSlot!.startTime, endSlot!.endTime);

      if (timeSlots.isEmpty) {
        showErrorDialog('Invalid slot selection.');
        return;
      }

      final response = await http.post(
        Uri.parse('${Constants.DEVANSH_IP}/api/booking/createbooking'),
        headers: {
          'authToken': '${authModel.authToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'turfId': widget.turfId,
          'date': utcBookingDate.toIso8601String(),
          'timeSlots': timeSlots,
          'adminId': widget.adminId,
        }),
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Booking Successful'),
              content: Text('Your booking has been confirmed.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(),
                      ),
                    );
                  },
                  child: Text('Back to Home'),
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to book slot: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error booking slot: $error');
      showErrorDialog('Failed to book slot. Please try again later.');
    }
  }

  List<String> _generateTimeSlots(String startTime, String endTime) {
    final start = DateFormat('HH:mm').parse(startTime);
    final end = DateFormat('HH:mm').parse(endTime);

    List<String> timeSlots = [];
    DateTime current = start;

    while (current.isBefore(end)) {
      final next = current.add(Duration(hours: 1));
      timeSlots.add(
          '${DateFormat('HH:mm').format(current)}-${DateFormat('HH:mm').format(next)}');
      current = next;
    }

    return timeSlots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Slot Booking'),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Date',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Text(
                        DateFormat.yMMMMd().format(date),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Available Slots',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8),
                      itemCount: slots.length,
                      itemBuilder: (context, index) {
                        final slot = slots[index];
                        final isSelected = isSlotInRange(slot);

                        return GestureDetector(
                          onTap: () => handleSlotSelection(slot),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: slot.isBooked
                                  ? Colors.grey
                                  : isSelected
                                      ? Colors.green
                                      : Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${slot.startTime}-${slot.endTime}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: handleBooking,
                        child: Text('Book Slot'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
