import 'package:flutter/material.dart';

class NearPoliceStation extends StatefulWidget {
  const NearPoliceStation({super.key});

  @override
  State<NearPoliceStation> createState() => _NearPoliceStationState();
}

class _NearPoliceStationState extends State<NearPoliceStation> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child:Text(
            "Near by polica station"
          )
        ),
      ),
    );
  }
}