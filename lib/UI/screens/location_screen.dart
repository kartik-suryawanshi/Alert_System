import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({Key? key}) : super(key: key);

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  LatLng? _currentLocation;
  Timer? _locationCheckTimer;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    fetchRiskZones();
    _locationCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkUserLocation();
    });
  }

  @override
  void dispose() {
    _locationCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchRiskZones() async {
    try {
      final response = await http.get(Uri.parse('https://emergency-alert-backend.onrender.com/api/high-risk-areas'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        _updateZones(data);
      } else {
        throw Exception('Failed to load risk zones');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void _updateZones(List<dynamic> data) {
    setState(() {
      _markers.clear();
      _circles.clear();
      for (var zone in data) {
        double lat = double.parse(zone['latitude'].toString());
        double lng = double.parse(zone['longitude'].toString());
        String riskLevel = zone['riskLevel'];
        String name = zone['name'];
        _addZone(lat, lng, riskLevel, name);
      }
    });
  }

  void _addZone(double lat, double lng, String riskLevel, String name) {
    Color zoneColor = _getZoneColor(riskLevel);
    _markers.add(Marker(
      markerId: MarkerId('$lat,$lng'),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(title: name, snippet: 'Risk Level: $riskLevel'),
    ));
    _circles.add(Circle(
      circleId: CircleId('$lat,$lng'),
      center: LatLng(lat, lng),
      radius: 200,
      fillColor: zoneColor.withOpacity(0.1),
      strokeColor: zoneColor,
      strokeWidth: 1,
    ));
  }

  Color _getZoneColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case "high":
        return Colors.red;
      case "moderate":
        return Colors.orange;
      case "low":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _checkUserLocation() {
    if (_currentLocation == null) return;
    for (var marker in _markers) {
      double distance = _calculateDistance(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        marker.position.latitude,
        marker.position.longitude,
      );
      if (distance <= 200) {
        _showAlert(marker.infoWindow.title!);
        break;
      }
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000;
    double dLat = _toRadians(lat2 - lat1);
    double dLng = _toRadians(lng2 - lng1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  void _showAlert(String zoneName) {
    Fluttertoast.showToast(
      msg: "You are in a high-risk zone: $zoneName",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  Future<void> requestPermissions() async {
    PermissionStatus status = await Permission.location.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Screen')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(18.5204, 73.8567),
          zoom: 12,
        ),
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        markers: _markers,
        circles: _circles,
        onCameraMove: (position) {
          _currentLocation = position.target;
        },
      ),
    );
  }
}