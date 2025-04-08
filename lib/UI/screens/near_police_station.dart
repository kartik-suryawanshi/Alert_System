import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../UI/services/chatbot_service.dart';

class NearPoliceStation extends StatefulWidget {
  const NearPoliceStation({Key? key}) : super(key: key);

  @override
  _NearPoliceStationState createState() => _NearPoliceStationState();
}

class _NearPoliceStationState extends State<NearPoliceStation> {
  final ChatbotService _chatbotService = ChatbotService();
  bool _loading = true;
  String? _error;
  double? _userLatitude;
  double? _userLongitude;
  String? _stationName;
  String? _googleMapUrl;

  @override
  void initState() {
    super.initState();
    _fetchNearestPoliceStation();
  }

  Future<void> _fetchNearestPoliceStation() async {
    try {
      // Step 1: Get user's current location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      });

      // Step 2: Call backend and get response string
      String response = await _chatbotService.getResponse(
        "Find nearest police station",
        latitude: position.latitude,
        longitude: position.longitude,
      );
      response = response.trim();

      // Step 3: Extract station name, latitude, and longitude using RegExp
      final nameRegex = RegExp(r"The nearest police station is (.+?)\.");
      final latLngRegex = RegExp(r"latitude ([\d.]+) and longitude ([\d.]+)");

      final nameMatch = nameRegex.firstMatch(response);
      final latLngMatch = latLngRegex.firstMatch(response);

      if (nameMatch != null && latLngMatch != null) {
        String stationName = nameMatch.group(1)!;

        // Remove any non-numeric characters except dot
        String latStr = latLngMatch.group(1)!.replaceAll(RegExp(r'[^0-9.]'), '');
        String lonStr = latLngMatch.group(2)!.replaceAll(RegExp(r'[^0-9.]'), '');

        print("Extracted latitude: $latStr");
        print("Extracted longitude: $lonStr");

        double policeLat = double.parse(latStr);
        double policeLng = double.parse(lonStr);

        String mapUrl =
            "https://www.google.com/maps/search/?api=1&query=$policeLat,$policeLng";

        setState(() {
          _stationName = stationName;
          _googleMapUrl = mapUrl;
          _loading = false;
        });
      }
      else {
        setState(() {
          _error = "Failed to parse location data from response: $response";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: ${e.toString()}";
        _loading = false;
      });
    }
  }

  Future<void> _launchMap() async {
    if (_googleMapUrl != null) {
      final Uri url = Uri.parse(_googleMapUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch map")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearest Police Station"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display error message if one exists.
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(
                        fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                // Display the station name and user location.
                Text(
                  _stationName ?? "Nearest Police Station",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Your Location: (${_userLatitude?.toStringAsFixed(4)}, ${_userLongitude?.toStringAsFixed(4)})",
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Button to open Google Maps.
                ElevatedButton.icon(
                  onPressed: _launchMap,
                  icon: const Icon(Icons.map),
                  label: const Text("Open in Google Maps"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
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
