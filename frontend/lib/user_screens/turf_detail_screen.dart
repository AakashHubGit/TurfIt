import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:turf_it/models/turf.dart';
import 'package:turf_it/user_screens/slot_booking_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';

class TurfDetail extends StatelessWidget {
  final Turf turf;

  TurfDetail({required this.turf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text('Turf Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Slider using CarouselSlider
            CarouselSlider(
              options: CarouselOptions(
                height: 300,
                enlargeCenterPage: true,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 3),
              ),
              items: turf.image.isNotEmpty
                  ? turf.image.map((imgBase64) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              image: DecorationImage(
                                image: MemoryImage(base64Decode(imgBase64)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList()
                  : [
                      Builder(
                        builder: (BuildContext context) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              image: DecorationImage(
                                image:
                                    AssetImage('assets/default_turf_image.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10),

                  // Price
                  Row(
                    children: [
                      Icon(Icons.attach_money, size: 22, color: Colors.green),
                      SizedBox(width: 5),
                      Text(
                        '₹${turf.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 22, color: Colors.blue),
                      SizedBox(width: 5),
                      Text(
                        turf.location,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Booking Hours
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 22, color: Colors.orange),
                      SizedBox(width: 5),
                      Text(
                        'Booking Hours: ${turf.openTime} - ${turf.closeTime}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Book Now Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SlotBookingScreen(
                                turfId: turf.id, adminId: turf.admin),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, // Button color
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Book Now',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
