import 'package:flutter/material.dart';
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
  Slot? startSlot;
  Slot? endSlot;
  bool loading = true;

  late AuthModel authModel;

  final _formKey = GlobalKey<FormState>();
  int totalPlayers = 0;
  int requestedPlayers = 0;

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
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != date) handleDateChange(picked);
  }

  void handleSlotSelection(Slot slot) {
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

  void handleSlotDeselection() {
    setState(() {
      startSlot = null;
      endSlot = null;
    });
  }

  bool isSlotInRange(Slot slot) {
    if (startSlot == null || endSlot == null) return false;

    final slotStartTime = DateFormat.Hm().parse(slot.startTime);
    final slotEndTime = DateFormat.Hm().parse(slot.endTime);
    final startSlotTime = DateFormat.Hm().parse(startSlot!.startTime);
    final endSlotTime = DateFormat.Hm().parse(endSlot!.endTime);

    return slotStartTime.isAtSameMomentAs(startSlotTime) ||
        slotEndTime.isAtSameMomentAs(endSlotTime) ||
        (slotStartTime.isAfter(startSlotTime) &&
            slotEndTime.isBefore(endSlotTime)) ||
        (slotStartTime.isBefore(startSlotTime) &&
            slotEndTime.isAfter(endSlotTime));
  }

  Future<void> handleBooking() async {
    try {
      if (startSlot == null || endSlot == null) {
        showErrorDialog('Please select continuous slots.');
        return;
      }
      if (_formKey.currentState!.validate()) {
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
            'totalPlayers': totalPlayers,
            'requestedPlayers': requestedPlayers,
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
                child: Form(
                  key: _formKey,
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
                        onTap: () => _selectDate(context),
                        child: Text(
                          DateFormat.yMMMMd().format(date),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Player Count Inputs
                      Text(
                        'Total Players',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Total Players',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the total number of players';
                          }
                          totalPlayers = int.parse(value);
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Requested Players',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Requested Players',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the requested number of players';
                          }
                          requestedPlayers = int.parse(value);
                          return null;
                        },
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
                          bool isSelected = isSlotInRange(slot);

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
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black,
                                  ),
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
            ),
    );
  }
}
