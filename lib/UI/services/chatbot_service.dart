import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatbotService {
  final String functionUrl = "https://emergency-alert-api.vercel.app/webhook";
  final String policeNumber = "100";
  static const platform = MethodChannel('com.example.emergency_alert_app/call');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getResponse(String query,
      {double? latitude, double? longitude}) async {
    final Map<String, dynamic> requestBody = {
      "queryInput": {
        "text": {"text": query, "languageCode": "en-US"}
      },
      "queryParams": {
        "payload": {
          "latitude": latitude,
          "longitude": longitude,
        }
      }
    };

    final response = await http.post(
      Uri.parse(functionUrl),
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
      },
      body: jsonEncode(requestBody),
    );

    print("Request Body: ${jsonEncode(requestBody)}");
    print("Response from function: ${response.body}");

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      String botResponse = data["fulfillmentText"];
      return botResponse;
    } else {
      print("Error from function: ${response.body}");
      return "Error: Unable to get response from function.";
    }
  }

  Future<void> callEmergency() async {
    if (Platform.isAndroid) {
      try {
        final result =
        await platform.invokeMethod('callPhone', {'number': policeNumber});
        print("Call result: $result");
      } on PlatformException catch (e) {
        print("Failed to call phone: ${e.message}");
      }
    } else if (Platform.isIOS) {
      final Uri phoneUri = Uri(scheme: 'tel', path: '100');
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch $phoneUri';
      }
    }
  }

  /// 🛡️ Feature: Check if user is in a safe zone
  Future<String> amISafeHere(double latitude, double longitude) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('Zones').get();

      for (var doc in snapshot.docs) {
        GeoPoint zoneLocation = doc['location'];
        double radius = (doc['radius'] as num).toDouble();
        String zoneType = doc['zone'];

        double distance = _calculateDistance(
            latitude, longitude, zoneLocation.latitude, zoneLocation.longitude);

        if (distance <= radius) {
          return "You are currently in a $zoneType zone.";
        }
      }
      return "You are not in any known zone. Proceed with caution.";
    } catch (e) {
      print("Error checking safety: $e");
      return "An error occurred while checking your safety.";
    }
  }

  /// 📍 Feature: Identify the zone type at user's location
  Future<String> checkMyZone(double latitude, double longitude) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('Zones').get();

      for (var doc in snapshot.docs) {
        GeoPoint zoneLocation = doc['location'];
        double radius = (doc['radius'] as num).toDouble();
        String zoneType = doc['zone'];

        double distance = _calculateDistance(
            latitude, longitude, zoneLocation.latitude, zoneLocation.longitude);

        if (distance <= radius) {
          return "Your current zone is classified as: $zoneType.";
        }
      }
      return "You are in a Normal zone but proceed with caution.";
    } catch (e) {
      print("Error checking zone: $e");
      return "An error occurred while identifying your zone.";
    }
  }

  /// 📏 Helper: Calculate distance between two coordinates (in meters)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.1415926535897932 / 180.0);
  }
}