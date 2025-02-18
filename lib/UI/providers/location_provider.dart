import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  Future<void> fetchCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      _currentPosition = position;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching location: $e');
    }
  }
}
