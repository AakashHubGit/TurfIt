import 'dart:async';

import 'package:flutter/material.dart';

class Turf {
  final String name;
  final List<String> size;
  final List<String> imgPath;
  final List<String> sports;
  final List<String> facility;
  final double rate;
  final String link;
  final int booking_start;
  final int booking_end;
  final List<Map<String, dynamic>> daySlots;
  final List<Map<String, dynamic>> reviews;
  final Map<String, dynamic> location;

  Turf({
    required this.name,
    required this.size,
    required this.imgPath,
    required this.sports,
    required this.facility,
    required this.rate,
    required this.link,
    required this.booking_start,
    required this.booking_end,
    required this.daySlots,
    required this.reviews,
    required this.location,
  });
}

class TurfCard extends StatelessWidget {
  final Turf turf;

  TurfCard({required this.turf});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Displaying Turf name and image
          ListTile(
            title: Text(turf.name),
            subtitle: Text('Rate: \$${turf.rate.toString()}'),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                turf.imgPath.isNotEmpty
                    ? turf.imgPath[0] // Displaying the first image if available
                    : 'https://via.placeholder.com/150', // Placeholder image URL
              ),
            ),
          ),
          // Displaying Turf details
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 5),
                Text('Sports: ${turf.sports.join(", ")}'),
                SizedBox(height: 5),
                Text('Facility: ${turf.facility.join(", ")}'),
                SizedBox(height: 5),
                Text(
                    'Booking Hours: ${turf.booking_start} - ${turf.booking_end}'),
                SizedBox(height: 5),
                // Handling location display
                if (turf.location != null &&
                    turf.location.containsKey('streetName') &&
                    turf.location.containsKey('city'))
                  Text(
                      'Location: ${turf.location["streetName"].join(", ")}, ${turf.location["city"]}'),
                SizedBox(height: 10),
                // Add more fields as per your Turf model if needed
              ],
            ),
          ),
        ],
      ),
    );
  }
}
