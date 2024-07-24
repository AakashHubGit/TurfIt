import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './turf_detail_screen.dart';
import '../screens/accounts_screen.dart'; // Import the AccountScreen
import 'package:turf_it/models/turf.dart';
import '../constant.dart';
import 'package:turf_it/user_screens/join_booking_screen.dart'; // Import JoinBookingPage

void main() {
  runApp(MaterialApp(
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Turf> turfs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTurfs();
  }

  Future<void> fetchTurfs() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.DEVANSH_IP}/api/turf/allturf'),
      );

      if (response.statusCode == 200) {
        List<dynamic> turfsData = jsonDecode(response.body);
        turfs = turfsData
            .map((turfJson) => Turf(
                  id: turfJson['_id'],
                  name: turfJson['name'],
                  size: List<String>.from(turfJson['size']),
                  imgPath: List<String>.from(turfJson['imgPath']),
                  sports: List<String>.from(turfJson['sports']),
                  facility: List<String>.from(turfJson['facility']),
                  rate: double.parse(turfJson['rate'].toString()),
                  link: turfJson['link'],
                  booking_start: turfJson['booking_start'],
                  booking_end: turfJson['booking_end'],
                  daySlots: (turfJson['daySlots'] as List)
                      .map((slotJson) => {
                            'date': DateTime.parse(slotJson['date']),
                            'slots': (slotJson['slots'] as List)
                                .map((slot) => {
                                      'startTime': slot['startTime'],
                                      'endTime': slot['endTime'],
                                      'status': slot['status']
                                    })
                                .toList()
                          })
                      .toList(),
                  reviews: (turfJson['reviews'] as List)
                      .map((reviewJson) => {
                            'review': reviewJson['review'],
                            'rating': reviewJson['rating'],
                            'username': reviewJson['username']
                          })
                      .toList(),
                  location: {
                    'streetName': turfJson['location']['streetName'],
                    'city': turfJson['location']['city'],
                  },
                ))
            .toList();
        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load turfs');
      }
    } catch (error) {
      print('Error fetching turfs: $error');
      // Handle error as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: turfs.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TurfDetail(turf: turfs[index]),
                            ),
                          );
                        },
                        child: TurfCard(turf: turfs[index]),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JoinBookingPage(),
                        ),
                      );
                    },
                    child: Text('Join a Booking'),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AccountScreen(),
            ),
          );
        },
        child: Icon(Icons.account_circle),
      ),
    );
  }
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
          // Turf Image Carousel
          Container(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: turf.imgPath.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.all(5),
                  width: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: AssetImage('assets/' + turf.imgPath[index]),
                      // image: NetworkImage("assets/" + turf.imgPath[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          // Turf Details
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  turf.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Rate: \$${turf.rate.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                SizedBox(height: 5),
                Text('Sports: ${turf.sports.join(", ")}'),
                SizedBox(height: 5),
                Text('Facility: ${turf.facility.join(", ")}'),
                SizedBox(height: 5),
                Text(
                    'Booking Hours: ${turf.booking_start} - ${turf.booking_end}'),
                SizedBox(height: 5),
                if (turf.location.containsKey('streetName') &&
                    turf.location.containsKey('city'))
                  Text(
                      'Location: ${turf.location["streetName"]}, ${turf.location["city"]}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
