import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  final LatLng userLocation;
  final LatLng policeStation;
  final List<LatLng> routePoints;

  MapScreen(this.userLocation, this.policeStation, this.routePoints);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Route to Police Station")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: userLocation,
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=VfyoBdUFoAN5yPInN9RN",
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: userLocation,
                width: 40,
                height: 40,
                child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
              ),
              Marker(
                point: policeStation,
                width: 40,
                height: 40,
                child: Icon(Icons.local_police, color: Colors.red, size: 40),
              ),
            ],
          ),
          if (routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(points: routePoints, strokeWidth: 4.0, color: Colors.blue),
              ],
            ),
        ],
      ),
    );
  }
}
