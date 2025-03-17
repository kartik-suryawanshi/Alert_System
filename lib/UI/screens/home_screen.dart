import 'package:alert_system/UI/screens/chatbot_screen.dart';
import 'package:alert_system/UI/screens/location_screen.dart';
import 'package:alert_system/UI/screens/near_police_station.dart';
import 'package:alert_system/UI/screens/profile_screen.dart';
import 'package:alert_system/widgets/quick_action_card.dart';
import 'package:alert_system/widgets/user_info_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_background_messenger/flutter_background_messenger.dart';
import 'package:logger/logger.dart';
import 'package:alert_system/widgets/navbar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = "Loading...";
  String location = "Loading...";
  String userId = "";
  int _currentIndex = 0;
  double _scale = 1.0;
  Position? _currentPosition;
  late List<Map<String, dynamic>> quickActions;
  final FlutterBackgroundMessenger messenger = FlutterBackgroundMessenger();


  final List<Widget> _screens = [
  NearPoliceStation(),
  LocationScreen(),
  ChatbotScreen(),
  UserProfile(),
];


  @override
  void initState() {
    super.initState();
    _initializeUser();

    quickActions = [
      {
        'title': 'Police',
        'icon': Icons.local_police,
        'color': Colors.redAccent,
        'action': () => _triggerActionWithAnimation(0),
      },
      {
        'title': 'Women Helpline',
        'icon': Icons.support_agent,
        'color': Colors.orange,
        'action': () => _triggerActionWithAnimation(1),
      },
      {
        'title': 'Nearby Help',
        'icon': Icons.people_alt,
        'color': Colors.blue,
        'action': () => _triggerActionWithAnimation(2),
      },
      {
        'title': 'Alert Friends',
        'icon': Icons.notifications,
        'color': Colors.green,
        'action': () => _triggerActionWithAnimation(3),
      },
    ];
  }

  Future<void> _initializeUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      //await _getUserData(user.uid);
      await _checkAndRequestPermissions();
    }
  }

  Future<bool> _checkAndRequestSMSPermission() async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
    }
    return status.isGranted;
  }

//   Future<void> _getUserData(String uid) async {
//   try {
//     DocumentSnapshot userDoc =
//         await FirebaseFirestore.instance.collection('users').doc(uid).get();

//     if (userDoc.exists) {
//       setState(() {
//         userData = userDoc.data() as Map<String, dynamic>?;

//         username = userData?['name'] ?? 'Anonymous';
//         location = userData?['location'] ?? 'Fetching location...';

//         _screens = [
//           NearPoliceStation(),
//           LocationScreen(),
//           ChatbotScreen(),
//           ProfileScreen(
//             username: userData?['username'] ?? '',
//             location: userData?['location'] ?? '',
//             mobileNumber: userData?['mobileNumber'] ?? '',
//             email: userData?['email'] ?? '',
//             age: userData?['age'] ?? '',
//             gender: userData?['gender'] ?? '',
//             profileImage: userData?['profileImage'] ?? '',
//             initialEmergencyContacts: List<Map<String, String>>.from(userData?['emergencyContacts'] ?? []),
//           ),
//         ];  
//       });
//     } else {
//       setState(() {
//         username = 'User not found';
//         location = 'Location not available';
//       });
//     }
//   } catch (e) {
//     print("Error fetching user data: $e");
//     setState(() {
//       username = 'Error loading username';
//       location = 'Error loading location';
//     });
//   }
// }


  Future<void> _checkAndRequestPermissions() async {
    if (await Permission.location.request().isGranted) {
      _getUserLocation();
    } else {
      setState(() {
        location = "Permission denied";
      });
    }
  }

 Future<void> _getUserLocation() async {
  try {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });

    _updateUserLocation(position);
    
    // Get location name including colony and city
    List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude);
    Placemark place = placemarks.isNotEmpty ? placemarks.first : Placemark();

    String colony = place.subLocality ?? "Unknown Colony";
    String city = place.locality ?? "Unknown City";

    String locationDetail = "$colony, $city"; // Format: "Colony, City"

    setState(() {
      location = locationDetail;  // Store colony and city name
    });

    //log.i("📍 Location: $locationDetail"); // Log location
  } catch (e) {
    print("Error fetching location: $e");
    setState(() {
      location = "Unable to get location";
    });
  }
}



  Future<void> _updateUserLocation(Position position) async {
    try {
      if (userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      }
    } catch (e) {
      print("Error updating location in Firestore: $e");
    }
  }

  Future<void> _getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];
      setState(() {
        location = "${place.locality}, ${place.country}";
      });
    } catch (e) {
      print("Error fetching location name: $e");
      setState(() {
        location = "Unknown location";
      });
    }
  }

  Future<void> _notifyNearbyUsers() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location not available. Try again later.")),
      );
      return;
    }

    double latitude = _currentPosition!.latitude;
    double longitude = _currentPosition!.longitude;

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    List<String> nearbyUserTokens = [];

    for (var doc in snapshot.docs) {
      if (doc.id == userId) continue;

      Map<String, dynamic>? userData = doc.data() as Map<String, dynamic>?;

      if (userData != null &&
          userData.containsKey('latitude') &&
          userData.containsKey('longitude')) {
        double userLat = userData['latitude'];
        double userLon = userData['longitude'];

        double distance =
            Geolocator.distanceBetween(latitude, longitude, userLat, userLon);

        if (distance <= 1000) {
          String? token = userData['fcmToken'];
          if (token != null) {
            nearbyUserTokens.add(token);
          }
        }
      }
    }

    if (nearbyUserTokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No nearby users found.")),
      );
      return;
    }

    String alertMessage =
        "🚨 Someone nearby needs help! 🚨\nLocation: https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";

    for (String token in nearbyUserTokens) {
      await _sendPushNotification(token, alertMessage);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Alert sent to nearby users!")),
    );
  }

  Future<void> _sendPushNotification(String token, String message) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'token': token,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _alertFriends(BuildContext context) async {
    // Check for SMS permissions
    bool smsPermission = await _checkAndRequestSMSPermission();
    if (!smsPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SMS permission not granted.')),
      );
      return;
    }

    // Check for location permissions
    bool locationPermission = await _checkLocationPermission();
    if (!locationPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission not granted.')),
      );
      return;
    }

    try {
      // Get the current location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      String googleMapsUrl =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      String message =
          "🚨 Emergency Alert! 🚨\nI am in danger! Please help me.\nMy location: $googleMapsUrl";

      // Fetch the user's emergency contacts from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      List<dynamic> emergencyContacts = userDoc['emergencyContacts'] ?? [];

      // Check if there are any emergency contacts
      if (emergencyContacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('No emergency contacts found in your profile.')),
        );
        return;
      }

      // Iterate through the emergency contacts and send SMS
      bool allSmsSent = true;
      for (var contact in emergencyContacts) {
        String number = contact['number']?.toString() ?? '';
        if (number.isEmpty) {
          print("Invalid phone number for contact: $contact");
          allSmsSent = false;
          continue;
        }
        try {
          await messenger.sendSMS(phoneNumber: number, message: message);
          print("SMS sent to $number");
        } catch (e) {
          print("Failed to send SMS to $number: $e");
          allSmsSent = false;
        }
      }

      // Show a SnackBar based on the success or failure of SMS sending
      if (allSmsSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Emergency alert sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Some alerts failed to send. Please check your contacts.')),
        );
      }
    } catch (e) {
      print("Error sending alert: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send alert. Please try again.')),
      );
    }
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  
  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _triggerActionWithAnimation(int index) {
    setState(() {
      _scale = 1.1;
    });

    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        _scale = 1.0;
      });
    });

    quickActions[index]['action']?.call();
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // Home Screen with Emergency Section & Grid
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                UserInfoHeader(username: username, location:location),
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Emergency Help Needed?",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          print("SOS Sent");
                        },
                        child: Text('SOS'),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Press the button to send SOS",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: quickActions.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _triggerActionWithAnimation(index),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          transform: Matrix4.identity()..scale(_scale),
                          child: QuickActionCard(
                            title: quickActions[index]['title'],
                            icon: quickActions[index]['icon'],
                            color: quickActions[index]['color'],
                            onTap: quickActions[index]['action'],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Other Screens
            NearPoliceStation(),
            LocationScreen(),
            ChatbotScreen(),
            UserProfile(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          // Modify this for any required FAB action
          Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()), // Replace with actual screen
    );
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
