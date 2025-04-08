import 'package:alert_system/UI/screens/chatbot_screen.dart';
import 'package:alert_system/UI/screens/location_screen.dart';
import 'package:alert_system/UI/screens/near_police_station.dart';
import 'package:alert_system/UI/screens/profile_screen.dart';
import 'package:alert_system/UI/screens/feedback_screen.dart'; // New import
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
    ChatBotScreen(),
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
        'action': () => _notifyNearbyUsers(),
      },
      {
        'title': 'Alert Friends',
        'icon': Icons.notifications,
        'color': Colors.green,
        'action': () => _alertFriends(context),
      },
      {
        'title': 'Feedback',
        'icon': Icons.feedback,
        'color': Colors.purple,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FeedbackScreen()),
          );
        },
      },
    ];
  }

  Future<void> _initializeUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      await _getUserData(user.uid);
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

  Future<void> _getUserData(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          username = userDoc['username'] ?? "Unknown User";
        });
      }
    } catch (e) {
      print("⚠️ Error fetching user data: $e");
    }
  }

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

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      Placemark place = placemarks.isNotEmpty ? placemarks.first : Placemark();
      String colony = place.subLocality ?? "Unknown Colony";
      String city = place.locality ?? "Unknown City";

      setState(() {
        location = "$colony, $city";
      });
    } catch (e) {
      setState(() {
        location = "Unable to get location";
      });
    }
  }

  Future<void> _updateUserLocation(Position position) async {
    try {
      if (userId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      }
    } catch (e) {
      print("Error updating location in Firestore: $e");
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

        double distance = Geolocator.distanceBetween(
            latitude, longitude, userLat, userLon);

        if (distance <= 1000) {
          String? token = userData['fcmToken'];
          if (token != null) {
            nearbyUserTokens.add(token);
          }
        }
      }
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
    bool smsPermission = await _checkAndRequestSMSPermission();
    if (!smsPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SMS permission not granted.')),
      );
      return;
    }

    bool locationPermission = await _checkLocationPermission();
    if (!locationPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission not granted.')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      String googleMapsUrl =
          "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      String message =
          "🚨 Emergency Alert! 🚨\nI am in danger! Please help me.\nMy location: $googleMapsUrl";

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      List<dynamic> emergencyContacts = userDoc['emergencyContacts'] ?? [];

      if (emergencyContacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No emergency contacts found.')),
        );
        return;
      }

      bool allSmsSent = true;
      for (var contact in emergencyContacts) {
        String number = contact['number']?.toString() ?? '';
        if (number.isEmpty) continue;

        try {
          await messenger.sendSMS(phoneNumber: number, message: message);
        } catch (e) {
          print("Failed to send SMS to $number: $e");
          allSmsSent = false;
        }
      }

      if (allSmsSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Emergency alert sent successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Some alerts failed to send.')),
        );
      }
    } catch (e) {
      print("Error sending alert: $e");
    }
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                UserInfoHeader(username: username, location: location),
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Emergency Help Needed?",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
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
            ..._screens,
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
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
