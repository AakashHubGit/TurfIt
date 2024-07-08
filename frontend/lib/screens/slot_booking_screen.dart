import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constant.dart';

const DEVANSH_IP = '192.168.1.3';

class TurfSlots extends StatefulWidget {
  final turf;

  TurfSlots({Key? key, this.turf}) : super(key: key);

  @override
  _TurfSlotsState createState() => _TurfSlotsState();
}

class _TurfSlotsState extends State<TurfSlots> {
  var availableSlots = [];
  var date = DateTime.now();
  var showDatePicker = false;
  var selectedSlots = [];
  var userName = "";
  var offUsers = [];
  var selectedOffUser;
  var userNumber = "";

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchOffUsers();
  }

  fetchData() async {
    try {
      var formattedDate = DateFormat('yyyy-MM-dd').format(date);

      var response = await http.post(
        Uri.parse(
            '${Constants.DEVANSH_IP}/api/turf/slots/${widget.turf['_id']}/$formattedDate'), // Pass date in the URL params
      );
      if (response.statusCode == 200) {
        setState(() {
          availableSlots = json.decode(response.body)['availableSlots'];
        });
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (error) {
      print('Error fetching slot data: $error');
    }
  }

  fetchOffUsers() async {
    try {
      var response = await http
          .get(Uri.parse('${Constants.DEVANSH_IP}/api/auth/offusers'));
      setState(() {
        offUsers = json.decode(response.body);
      });
    } catch (error) {
      print('Error fetching off users: $error');
    }
  }

  handleOffUserChange(value) {
    var selectedUser = offUsers.firstWhere((user) => user['number'] == value,
        orElse: () => {});
    setState(() {
      selectedOffUser = value;
      userName = selectedUser.isNotEmpty ? selectedUser['name'] : "";
      userNumber =
          selectedUser.isNotEmpty ? selectedUser['number'].toString() : "";
    });
  }

  handleDateChange(DateTime selectedDate) {
    setState(() {
      date = selectedDate;
      showDatePicker = false;
    });
    fetchData();
  }

  handleSlotSelection(slot) {
    setState(() {
      if (selectedSlots.isEmpty) {
        selectedSlots.add(slot);
      } else {
        var lastSelectedSlot = selectedSlots.last;
        var lastEndTime = DateFormat.Hm().parse(lastSelectedSlot['endTime']);
        var newStartTime = DateFormat.Hm().parse(slot['startTime']);
        if (lastEndTime == newStartTime) {
          selectedSlots.add(slot);
        } else {
          selectedSlots = [slot];
        }
      }
    });
  }

  handleSlotDeselection() {
    setState(() {
      selectedSlots = [];
    });
  }

  handleBooking() async {
    try {
      if (selectedSlots.isEmpty ||
          userName.trim().isEmpty ||
          userNumber.trim().isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Error"),
              content: Text(
                  "Please select consecutive slots and enter user information"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
        return;
      }

      var response = await http.post(
        Uri.parse('${Constants.DEVANSH_IP}/api/booking/createofflinebooking'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'turfId': widget.turf['_id'],
          'name': userName,
          'number': userNumber,
          'date': date.toString(),
          'startTime': selectedSlots.first['startTime'],
          'endTime': selectedSlots.last['endTime'],
        }),
      );

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Booking Successful"),
            content: Text("Your booking has been confirmed."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/receiptPage',
                    arguments: {
                      'booking': json.decode(response.body)['booking'],
                      'user': 'Owner',
                    },
                  );
                },
                child: Text("View Receipt"),
              ),
            ],
          );
        },
      );
    } catch (error) {
      print('Error booking slot: $error');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Booking Failed"),
            content: Text("Failed to book the slot. Please try again later."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Turf Slots"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Date Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Date",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                DatePickerWidget(
                  initialDate: date,
                  onSelected: handleDateChange,
                ),
              ],
            ),

            SizedBox(height: 20),
            // Available Slots Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Available Slots",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: availableSlots.map<Widget>((slot) {
                    bool isSelected = selectedSlots.contains(slot);
                    return GestureDetector(
                      onTap: () => handleSlotSelection(slot),
                      child: Container(
                        margin: EdgeInsets.only(
                            bottom: 10), // Add margin between slots
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green : Colors.white,
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${DateFormat.jm().format(DateFormat.Hm().parse(slot['startTime']))}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '-',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${DateFormat.jm().format(DateFormat.Hm().parse(slot['endTime']))}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (selectedSlots.isNotEmpty)
                  ElevatedButton(
                    onPressed: handleSlotDeselection,
                    child: Text("Cancel Slots"),
                  ),
              ],
            ),

            SizedBox(height: 20),

            // Select Offline User Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Select Offline User",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                DropdownButtonFormField(
                  value: selectedOffUser,
                  onChanged: handleOffUserChange,
                  items: offUsers.map<DropdownMenuItem>((user) {
                    return DropdownMenuItem(
                      value: user['number'],
                      child: Text(user['name']),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select an Offline User',
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // User Information Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "User Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Enter name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      userName = value;
                    });
                  },
                  initialValue: userName, // Set initial value
                ),
                SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Enter number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {
                    setState(() {
                      userNumber = value;
                    });
                  },
                  initialValue: userNumber, // Set initial value
                ),
              ],
            ),
            SizedBox(height: 20),

            // Book Selected Slots Button
            if (selectedSlots.isNotEmpty)
              ElevatedButton(
                onPressed: handleBooking,
                child: Text("Book Selected Slots"),
              ),
          ],
        ),
      ),
    );
  }
}

class DatePickerWidget extends StatelessWidget {
  final DateTime initialDate;
  final Function(DateTime) onSelected;

  DatePickerWidget({required this.initialDate, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Date:',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              DateFormat.yMMMMd().format(initialDate),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(Duration(days: 1)),
      lastDate: DateTime.now().add(Duration(days: 30)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green, // Your desired color here
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != initialDate) {
      onSelected(pickedDate);
    }
  }
}
