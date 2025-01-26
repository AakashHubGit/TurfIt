import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:turf_it/models/auth_model.dart';
import 'package:turf_it/models/slot_model.dart';
import 'package:turf_it/services/slot_service.dart';
import 'package:turf_it/user_screens/user_home_screen.dart';

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
  late SlotService slotService;

  @override
  void initState() {
    super.initState();
    slotService = SlotService();
    fetchAuthToken();
  }

  Future<void> fetchAuthToken() async {
    try {
      authModel = await slotService.fetchAuthToken();
      fetchSlots();
    } catch (error) {
      showErrorDialog('Authentication failed. Please log in again.');
    }
  }

  Future<void> fetchSlots() async {
    try {
      final fetchedSlots = await slotService.fetchSlots(
          widget.turfId, authModel.authToken, date);
      setState(() {
        slots = fetchedSlots;
        loading = false;
      });
      fetchBookedSlots();
    } catch (error) {
      showErrorDialog('Failed to fetch slot data. Please try again later.');
    }
  }

  Future<void> fetchBookedSlots() async {
    try {
      final bookedSlots = await slotService.fetchBookedSlots(
          widget.turfId, authModel.authToken, date);
      setState(() {
        slots = slots.map((slot) {
          if (bookedSlots.any((bookedSlot) => slotService.isTimeOverlapping(
              slot.startTime,
              slot.endTime,
              bookedSlot.startTime,
              bookedSlot.endTime))) {
            slot.isBooked = true;
          }
          return slot;
        }).toList();
      });
    } catch (error) {
      showErrorDialog(
          'Failed to fetch booked slot data. Please try again later.');
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

    return (startSlotTime.isBefore(endSlotTime)) &&
        (slotStartTime.isAtSameMomentAs(startSlotTime) ||
            slotEndTime.isAtSameMomentAs(endSlotTime) ||
            (slotStartTime.isAfter(startSlotTime) &&
                slotEndTime.isBefore(endSlotTime)));
  }

  Future<void> handleBooking() async {
    try {
      if (startSlot == null || endSlot == null) {
        showErrorDialog('Please select continuous slots.');
        return;
      }

      List<String> timeSlots =
          slotService.generateTimeSlots(startSlot!.startTime, endSlot!.endTime);

      if (timeSlots.isEmpty) {
        showErrorDialog('Invalid slot selection.');
        return;
      }

      await slotService.handleBooking(widget.turfId, widget.adminId,
          utcBookingDate, timeSlots, authModel.authToken);

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
    } catch (error) {
      showErrorDialog('Failed to book slot. Please try again later.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title:
            Text('Slot Booking', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
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
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Text(
                        DateFormat.yMMMMd().format(date),
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Available Slots',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
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
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: slot.isBooked
                                  ? Colors.grey
                                  : isSelected
                                      ? Colors.green
                                      : Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${slot.startTime}-${slot.endTime}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                        ),
                        onPressed: handleBooking,
                        child: Text(
                          'Book Slot',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
