import 'package:flutter/material.dart';

class NearPoliceStation extends StatefulWidget {
  @override
  _NearPoliceStationState createState() => _NearPoliceStationState();
}

class _NearPoliceStationState extends State<NearPoliceStation> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nearest Police Station")),
      body: Center(
        child: Text("Nearest Police Station Screen"),
      ),
    );
  }
}