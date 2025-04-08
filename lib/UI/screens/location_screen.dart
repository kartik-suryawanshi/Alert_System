import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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
    _getCurrentLocation();
    fetchRiskZonesFromFirebase();
    _locationCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkUserLocation();
    });
  }

  @override
  void dispose() {
    _locationCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    await Permission.location.request();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _markers.add(Marker(
        markerId: const MarkerId("currentLocation"),
        position: _currentLocation!,
        infoWindow: const InfoWindow(title: "You"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    });

    // Animate camera to user's current location
    if (mapController != null) {
      mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
    }
  }

  Future<void> fetchRiskZonesFromFirebase() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore.collection('Zones').get();

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (data['location'] is GeoPoint) {
        GeoPoint location = data['location'];
        double lat = location.latitude;
        double lng = location.longitude;
        String zoneType = data['zone']?.toString().toLowerCase() ?? 'unknown';
        String name = data['name'] ?? 'Unknown';
        int radius = data['radius'] ?? 200;

        _addZone(lat, lng, zoneType, name, radius);
      }
    }
  }

  void _addZone(double lat, double lng, String zoneType, String name, int radius) {
    Color zoneColor = _getZoneColor(zoneType);
    LatLng position = LatLng(lat, lng);

    setState(() {
      // Removed zone marker creation
      _circles.add(Circle(
        circleId: CircleId('$lat,$lng'),
        center: position,
        radius: radius.toDouble(),
        fillColor: zoneColor.withOpacity(0.2),
        strokeColor: zoneColor,
        strokeWidth: 2,
      ));
    });
  }


  Color _getZoneColor(String zoneType) {
    switch (zoneType) {
      case 'danger':
        return Colors.red;
      case 'safe':
        return Colors.green;
      case 'normal':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _checkUserLocation() {
    if (_currentLocation == null) return;

    for (var circle in _circles) {
      double distance = _calculateDistance(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        circle.center.latitude,
        circle.center.longitude,
      );
      if (distance <= circle.radius) {
        _showAlert(circle.circleId.value);
        break;
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // in meters
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * (pi / 180);

  void _showAlert(String zoneName) {
    Fluttertoast.showToast(
      msg: "You are in a risk zone: $zoneName",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Alert Map')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation ?? const LatLng(18.5204, 73.8567),
          zoom: 13,
        ),
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        markers: _markers,
        circles: _circles,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
