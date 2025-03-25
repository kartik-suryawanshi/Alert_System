import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'map_screen.dart';

class NearPoliceStation extends StatefulWidget {
  @override
  _NearPoliceStationState createState() => _NearPoliceStationState();
}

class _NearPoliceStationState extends State<NearPoliceStation> {
  LatLng? userLocation;
  Map<String, dynamic>? policeStation;
  bool isLoading = true;
  String? errorMessage;

  static const String nominatimUrl =
      'https://nominatim.openstreetmap.org/search';
  static const String osrmUrl =
      'https://router.project-osrm.org/route/v1/driving';

  @override
  void initState() {
    super.initState();
    _fetchUserLocationAndPoliceStation();
  }

  Future<void> _fetchUserLocationAndPoliceStation() async {
    try {
      final position = await _getCurrentLocation();
      print("User Location: ${position.latitude}, ${position.longitude}");

      final policeData = await  _fetchNearestPoliceStationFromDB(position);
      if (policeData.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = "No police station found nearby.";
        });
        return;
      }

      // Pick the nearest station within 10 km
      policeStation = _getClosestStation(position, policeData);
      if (policeStation == null) {
        setState(() {
          isLoading = false;
          errorMessage = "No police station found within 10 km.";
        });
        return;
      }

      setState(() {
        userLocation = LatLng(position.latitude, position.longitude);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Failed to fetch data: ${e.toString()}";
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) throw Exception("Location permission denied");

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return false;
    }
    return true;
  }

  Future<Map<String, dynamic>?> _fetchNearestPoliceStationFromDB() async {
  try {
    // 🔹 Fetch user details from your database (replace with actual database call)
    String colony = "Your Colony Name";  // Replace with actual DB fetch
    String city = "Your City Name";      // Replace with actual DB fetch

    if (colony.isEmpty || city.isEmpty) {
      throw Exception("Colony or city information missing");
    }

    // 🔹 Construct search query with colony and city
    String query = Uri.encodeComponent("$colony, $city, police station");

    final response = await http.get(Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=$query&addressdetails=1&limit=5'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("Police Station Data: $data");

      if (data.isNotEmpty) {
        return data.first as Map<String, dynamic>;
      } else {
        throw Exception("No police station found near $colony, $city.");
      }
    } else {
      throw Exception("Failed to fetch police station data");
    }
  } catch (e) {
    print("Error: $e");
    return null;
  }
}


  Map<String, dynamic>? _getClosestStation(
      Position position, List<Map<String, dynamic>> stations) {
    double userLat = position.latitude;
    double userLon = position.longitude;

    List<Map<String, dynamic>> nearbyStations = stations.where((station) {
      double stationLat = double.parse(station['lat']);
      double stationLon = double.parse(station['lon']);
      double distance =
          _calculateDistance(userLat, userLon, stationLat, stationLon);

      return distance <= 10; // Only keep stations within 10 km
    }).toList();

    if (nearbyStations.isEmpty) return null;

    // Return the closest police station
    nearbyStations.sort((a, b) {
      double latA = double.parse(a['lat']);
      double lonA = double.parse(a['lon']);
      double latB = double.parse(b['lat']);
      double lonB = double.parse(b['lon']);

      double distA = _calculateDistance(userLat, userLon, latA, lonA);
      double distB = _calculateDistance(userLat, userLon, latB, lonB);

      return distA.compareTo(distB);
    });

    return nearbyStations.first;
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius in km
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in km
  }

  void _showMap() async {
    if (policeStation == null || userLocation == null) return;

    final lat = double.parse(policeStation!['lat']);
    final lon = double.parse(policeStation!['lon']);

    try {
      final route = await _getRoute(
          userLocation!.latitude, userLocation!.longitude, lat, lon);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MapScreen(userLocation!, LatLng(lat, lon), route),
        ),
      );
    } catch (e) {
      setState(() => errorMessage = "Failed to fetch route: ${e.toString()}");
    }
  }

  Future<List<LatLng>> _getRoute(
      double startLat, double startLon, double endLat, double endLon) async {
    final response = await http.get(Uri.parse(
        '$osrmUrl/$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Route Data: $data");

      final coordinates = data['routes'][0]['geometry']['coordinates'];
      return coordinates
          .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
          .toList();
    } else {
      throw Exception("Failed to fetch route data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nearest Police Station")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child:
                      Text(errorMessage!, style: TextStyle(color: Colors.red)))
              : ListTile(
                  title: Text(policeStation!['display_name']),
                  subtitle: Text("Tap to view on map"),
                  leading: Icon(Icons.local_police, color: Colors.blue),
                  onTap: _showMap,
                ),
    );
  }
}
