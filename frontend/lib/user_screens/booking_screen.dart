import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_model.dart';
import '../models/slot_model.dart';
import '../constant.dart';

class SlotBookingScreen extends StatefulWidget {
  final String turfId;

  SlotBookingScreen({required this.turfId});

  @override
  _SlotBookingScreenState createState() => _SlotBookingScreenState();
}

class _SlotBookingScreenState extends State<SlotBookingScreen> {
  List<Slot> availableSlots = [];
  List<Slot> bookedSlots = [];
  DateTime date = DateTime.now();
  bool showDatePicker = false;
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
      // Handle case where authToken is not found (e.g., redirect to login)
    } else {
      authModel = AuthModel(
          id: 1, authToken: authToken); // Replace with actual user details
      fetchData();
    }
  }

  Future<void> fetchData() async {
    try {
      final response = await http.post(
        Uri.parse(
            '${Constants.DEVANSH_IP}/api/turf/slots/${widget.turfId}/${DateFormat('yyyy-MM-dd').format(date)}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          availableSlots = (data['availableSlots'] as List)
              .map((slot) => Slot.fromJson(slot))
              .toList();
          bookedSlots = (data['bookedSlots'] as List)
              .map((slot) => Slot.fromJson(slot))
              .toList();
          loading = false;
        });
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (error) {
      print('Error fetching slot data: $error');
      showErrorDialog('Failed to fetch slot data. Please try again later.');
    }
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
      fetchData();
      showDatePicker = false;
    });
  }

  void handleSlotSelection(Slot slot) {
    setState(() {
      if (startSlot == null ||
          (startSlot != null && slot.startTime == startSlot!.endTime)) {
        startSlot = startSlot ?? slot;
        endSlot = slot;
      } else if (slot.startTime == endSlot!.endTime) {
        endSlot = slot;
      } else {
        startSlot = slot;
        endSlot = slot;
      }
    });
  }

  void handleSlotDeselection() {
    setState(() {
      startSlot = null;
      endSlot = null;
    });
  }

  bool isSlotInRange(Slot slot) {
    return (DateFormat.Hm()
                .parse(slot.startTime)
                .isAfter(DateFormat.Hm().parse(startSlot!.startTime)) &&
            DateFormat.Hm()
                .parse(slot.endTime)
                .isBefore(DateFormat.Hm().parse(endSlot!.endTime))) ||
        (DateFormat.Hm()
                .parse(slot.startTime)
                .isBefore(DateFormat.Hm().parse(startSlot!.startTime)) &&
            DateFormat.Hm()
                .parse(slot.endTime)
                .isAfter(DateFormat.Hm().parse(endSlot!.endTime)));
  }

  Future<void> handleBooking() async {
    try {
      if (startSlot == null || endSlot == null) {
        showErrorDialog('Please select continuous slots.');
        return;
      }
      final response = await http.post(
        Uri.parse('${Constants.DEVANSH_IP}/api/booking/createbooking'),
        headers: {
          'authToken': authModel.authToken,
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'turfId': widget.turfId,
          'date': DateFormat('yyyy-MM-dd').format(date),
          'startTime': startSlot!.startTime,
          'endTime': endSlot!.endTime,
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
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/receiptPage', arguments: {
                      'booking': jsonDecode(response.body)['booking'],
                      'user': 'Player',
                    });
                  },
                  child: Text('View Receipt'),
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to book slot');
      }
    } catch (error) {
      print('Error booking slot: $error');
      showErrorDialog('Failed to book slot. Please try again later.');
    }
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
                    // Date Selection Section
                    Text(
                      'Select Date',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => setState(() => showDatePicker = true),
                      child: Text(
                        DateFormat.yMMMMd().format(date),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    if (showDatePicker)
                      Container(
                        height: 200,
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          initialDateTime: date,
                          minimumDate:
                              DateTime.now().subtract(Duration(days: 1)),
                          maximumDate: DateTime.now().add(Duration(days: 30)),
                          onDateTimeChanged: handleDateChange,
                        ),
                      ),
                    SizedBox(height: 20),

                    // Available Slots Section
                    Text(
                      'Available Slots',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: availableSlots.length,
                      itemBuilder: (context, index) {
                        Slot slot = availableSlots[index];
                        bool isSelected = startSlot != null &&
                            endSlot != null &&
                            isSlotInRange(slot);

                        return GestureDetector(
                          onTap: () => handleSlotSelection(slot),
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.green : Colors.grey[300],
                              borderRadius: BorderRadius.circular(5),
                              border: isSelected
                                  ? Border.all(color: Colors.green, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${DateFormat.jm().format(DateFormat.Hm().parse(slot.startTime))} - ${DateFormat.jm().format(DateFormat.Hm().parse(slot.endTime))}',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (startSlot != null && endSlot != null)
                      ElevatedButton(
                        onPressed: handleSlotDeselection,
                        child: Text('Deselect Slots'),
                      ),
                    SizedBox(height: 20),

                    // Book Selected Slots Button
                    if (startSlot != null && endSlot != null)
                      Center(
                        child: ElevatedButton(
                          onPressed: handleBooking,
                          child: Text('Book Selected Slots'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
