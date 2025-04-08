//
//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class FeedbackScreen extends StatefulWidget {
//   @override
//   _FeedbackScreenState createState() => _FeedbackScreenState();
// }
//
// class _FeedbackScreenState extends State<FeedbackScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _locationNameController = TextEditingController();
//   final TextEditingController _latitudeController = TextEditingController();
//   final TextEditingController _longitudeController = TextEditingController();
//   final TextEditingController _summaryController = TextEditingController();
//
//   String _selectedRiskType = 'Safe';
//   final List<String> _riskOptions = ['Safe', 'Moderate', 'High'];
//
//   /// Formats the latitude and longitude into a single string.
//   /// For example: "[18.5204000000° N, 73.8567000000° E]"
//   String _formatCoordinates(double lat, double long) {
//     // Format numbers to 10 decimal places.
//     String latStr = lat.toStringAsFixed(10);
//     String longStr = long.toStringAsFixed(10);
//     return "[$latStr° N, $longStr° E]";
//   }
//
//   Future<void> _submitFeedback() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         // Parse latitude and longitude.
//         final double lat = double.parse(_latitudeController.text.trim());
//         final double long = double.parse(_longitudeController.text.trim());
//
//         // Format the coordinates as a string.
//         final String formattedLocation = _formatCoordinates(lat, long);
//
//         // Prepare the data to be stored.
//         final data = {
//           'name': _locationNameController.text.trim(),
//           'location': formattedLocation, // formatted location string
//           'radius': 500,
//           'zone': _selectedRiskType,
//           'summary': _summaryController.text.trim(),
//           'timestamp': FieldValue.serverTimestamp(),
//         };
//
//         // Store the data in the "Zones" collection.
//         await FirebaseFirestore.instance.collection('Zones').add(data);
//
//         // Show a confirmation message.
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Feedback submitted successfully!')),
//         );
//
//         // Clear all the controllers.
//         _locationNameController.clear();
//         _latitudeController.clear();
//         _longitudeController.clear();
//         _summaryController.clear();
//         setState(() {
//           _selectedRiskType = 'Safe';
//         });
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error submitting feedback: $e')),
//         );
//       }
//     }
//   }
//
//   String? _validateDouble(String? value, String fieldName) {
//     if (value == null || value.isEmpty) return '$fieldName is required';
//     final parsed = double.tryParse(value);
//     if (parsed == null) return '$fieldName must be a number';
//     return null;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Submit Feedback"),
//         backgroundColor: Colors.orange,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text("Location Name", style: TextStyle(fontWeight: FontWeight.bold)),
//               TextFormField(
//                 controller: _locationNameController,
//                 decoration: InputDecoration(
//                   hintText: "e.g. Koregaon Park, Pune",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) => value == null || value.isEmpty ? 'Location name is required' : null,
//               ),
//               SizedBox(height: 15),
//               Text("Latitude", style: TextStyle(fontWeight: FontWeight.bold)),
//               TextFormField(
//                 controller: _latitudeController,
//                 keyboardType: TextInputType.numberWithOptions(decimal: true),
//                 decoration: InputDecoration(
//                   hintText: "e.g. 18.5204",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) => _validateDouble(value, "Latitude"),
//               ),
//               SizedBox(height: 15),
//               Text("Longitude", style: TextStyle(fontWeight: FontWeight.bold)),
//               TextFormField(
//                 controller: _longitudeController,
//                 keyboardType: TextInputType.numberWithOptions(decimal: true),
//                 decoration: InputDecoration(
//                   hintText: "e.g. 73.8567",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) => _validateDouble(value, "Longitude"),
//               ),
//               SizedBox(height: 15),
//               Text("Risk Type (Zone)", style: TextStyle(fontWeight: FontWeight.bold)),
//               DropdownButtonFormField<String>(
//                 value: _selectedRiskType,
//                 decoration: InputDecoration(border: OutlineInputBorder()),
//                 items: _riskOptions.map((risk) {
//                   return DropdownMenuItem(
//                     value: risk,
//                     child: Text(risk),
//                   );
//                 }).toList(),
//                 onChanged: (value) {
//                   if (value != null) {
//                     setState(() {
//                       _selectedRiskType = value;
//                     });
//                   }
//                 },
//               ),
//               SizedBox(height: 15),
//               Text("Summary", style: TextStyle(fontWeight: FontWeight.bold)),
//               TextFormField(
//                 controller: _summaryController,
//                 maxLines: 5,
//                 decoration: InputDecoration(
//                   hintText: "Describe the situation, any incidents, etc.",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) => value == null || value.isEmpty ? 'Summary is required' : null,
//               ),
//               SizedBox(height: 30),
//               Center(
//                 child: ElevatedButton(
//                   onPressed: _submitFeedback,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                     padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   child: Text("Submit Feedback", style: TextStyle(fontSize: 16)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class FeedbackScreen extends StatefulWidget {
  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationNameController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();

  double? _latitude;
  double? _longitude;

  String _selectedRiskType = 'Safe';
  final List<String> _riskOptions = ['Safe', 'Normal', 'Danger'];

  String _formatCoordinates(double lat, double long) {
    String latStr = lat.toStringAsFixed(10);
    String longStr = long.toStringAsFixed(10);
    return "[$latStr° N, $longStr° E]";
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          throw Exception('Location permission not granted');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location fetched successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch location: $e')),
      );
    }
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fetch your location first')),
        );
        return;
      }

      try {
        final data = {
          'name': _locationNameController.text.trim(),
          'location': GeoPoint(_latitude!, _longitude!), // ✅ Save as GeoPoint
          'radius': 500,
          'zone': _selectedRiskType,
          'summary': _summaryController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection('Zones').add(data);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feedback submitted successfully!')),
        );

        _locationNameController.clear();
        _summaryController.clear();
        setState(() {
          _selectedRiskType = 'Safe';
          _latitude = null;
          _longitude = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting feedback: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Submit Feedback"),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Location Name", style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _locationNameController,
                decoration: InputDecoration(
                  hintText: "e.g. Koregaon Park, Pune",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Location name is required' : null,
              ),
              SizedBox(height: 15),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _fetchLocation,
                    icon: Icon(Icons.my_location),
                    label: Text("Fetch My Location"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 15),
                  if (_latitude != null && _longitude != null)
                    Expanded(
                      child: Text(
                        _formatCoordinates(_latitude!, _longitude!),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    )
                ],
              ),
              SizedBox(height: 15),

              Text("Risk Type (Zone)", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _selectedRiskType,
                decoration: InputDecoration(border: OutlineInputBorder()),
                items: _riskOptions.map((risk) {
                  return DropdownMenuItem(
                    value: risk,
                    child: Text(risk),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRiskType = value;
                    });
                  }
                },
              ),
              SizedBox(height: 15),

              Text("Summary", style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _summaryController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Describe the situation, any incidents, etc.",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Summary is required' : null,
              ),
              SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Submit Feedback", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
