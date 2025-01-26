import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:turf_it/models/auth_model.dart';
import 'package:turf_it/models/slot_model.dart';
import '../constant.dart';

class SlotService {
  Future<AuthModel> fetchAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('authToken');
    if (authToken == null) {
      throw 'Authentication failed. Please log in again.';
    } else {
      return AuthModel(id: 1, authToken: authToken);
    }
  }

  Future<List<Slot>> fetchSlots(
      String turfId, String authToken, DateTime date) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Constants.DEVANSH_IP}/api/turf/$turfId/slots?date=${DateFormat('yyyy-MM-dd').format(date)}'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data']['slots'] as List)
            .map((slot) => Slot.fromJson(slot))
            .toList();
      } else {
        throw Exception('Failed to fetch slots: ${response.reasonPhrase}');
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<List<Slot>> fetchBookedSlots(
      String turfId, String authToken, DateTime date) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Constants.DEVANSH_IP}/api/booking/$turfId/booked-slots?date=${DateFormat('yyyy-MM-dd').format(date)}'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data']['bookedSlots'] as List)
            .map((slot) => Slot.fromJson(slot))
            .toList();
      } else {
        throw Exception(
            'Failed to fetch booked slots: ${response.reasonPhrase}');
      }
    } catch (error) {
      rethrow;
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

  Future<void> handleBooking(String turfId, String adminId,
      DateTime bookingDate, List<String> timeSlots, String authToken) async {
    try {
      final response = await http.post(
        Uri.parse('${Constants.DEVANSH_IP}/api/booking/createbooking'),
        headers: {
          'authToken': authToken,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'turfId': turfId,
          'date': bookingDate.toIso8601String(),
          'timeSlots': timeSlots,
          'adminId': adminId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to book slot: ${response.reasonPhrase}');
      }
    } catch (error) {
      rethrow;
    }
  }

  List<String> generateTimeSlots(String startTime, String endTime) {
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
}
