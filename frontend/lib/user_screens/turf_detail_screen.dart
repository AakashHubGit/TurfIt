import 'package:flutter/material.dart';
import 'package:turf_it/models/turf.dart';
import 'package:turf_it/user_screens/booking_screen.dart'; // Assuming Turf class is defined in turf.dart

class TurfDetail extends StatelessWidget {
  final Turf turf;

  TurfDetail({required this.turf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Turf Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            Container(
              height: 300,
              child: PageView.builder(
                itemCount: turf.imgPath.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    "assets/${turf.imgPath[index]}",
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Turf Name
                  Text(
                    turf.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),

                  // Rate
                  Row(
                    children: [
                      Icon(Icons.attach_money, size: 20),
                      SizedBox(width: 5),
                      Text(
                        'Rate: \$${turf.rate.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Sports
                  Row(
                    children: [
                      Icon(Icons.sports_soccer, size: 20),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Sports: ${turf.sports.join(", ")}',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Facility
                  Row(
                    children: [
                      Icon(Icons.meeting_room, size: 20),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Facility: ${turf.facility.join(", ")}',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 20),
                      SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Location: ${turf.location["streetName"]}, ${turf.location["city"]}',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Booking Hours
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 20),
                      SizedBox(width: 5),
                      Text(
                        'Booking Hours: ${turf.booking_start} - ${turf.booking_end}',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Book Now Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SlotBookingScreen(
                              turfId: turf.id), // Pass turfId to SlotBooking
                        ),
                      );
                    },
                    child: Text('Book Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
