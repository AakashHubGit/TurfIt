import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './turf_detail_screen.dart';
import 'accounts_screen.dart';
import '../models/turf.dart';
import '../constant.dart';

void main() {
  runApp(MaterialApp(
    home: HomeScreen(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
    ),
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
                  size: turfJson['size'],
                  location: turfJson['location'],
                  admin: turfJson['admin'],
                  openTime: turfJson['openTime'],
                  closeTime: turfJson['closeTime'],
                  price: double.parse(turfJson['price'].toString()),
                  slotDuration: int.parse(turfJson['slotDuration'].toString()),
                  image: List<String>.from(
                      turfJson['images']), // Parse as a list of Base64 strings
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 5,
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: turfs.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TurfDetail(turf: turfs[index]),
                        ),
                      );
                    },
                    child: TurfCard(turf: turfs[index]),
                  );
                },
              ),
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
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.account_circle, size: 30),
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
      margin: EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the first image from the images array
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: turf.image.isNotEmpty
                  ? Image.memory(
                      base64Decode(
                          turf.image[0]), // Decode the first Base64 image
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 100,
                      width: 100,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[600],
                        size: 50,
                      ),
                    ),
            ),
            SizedBox(width: 16),
            // Display the turf details on the right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turf.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Size: ${turf.size}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Location: ${turf.location}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Price: ₹${turf.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Booking Hours: ${turf.openTime} - ${turf.closeTime}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
