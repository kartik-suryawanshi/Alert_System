import 'package:alert_system/UI/auth/login_screen.dart';
import 'package:alert_system/UI/services/userdata_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0C0C0C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Profile",
          style: TextStyle(
            fontFamily: 'Font1',
            fontSize: 20,
            color: Color(0xffffffff),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              height: 50,
              width: 50,
              child: FloatingActionButton(
                splashColor: Colors.red,
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                },
                backgroundColor: const Color.fromARGB(255, 255, 77, 0),
                child: const Icon(Icons.logout),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xff0C0C0C),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xffFFA500)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "No data available",
                style: TextStyle(
                  color: Color(0xffffffff),
                  fontFamily: 'Font1',
                  fontSize: 15,
                ),
              ),
            );
          }

          Map<String, dynamic>? userData = snapshot.data!.data() as Map<String, dynamic>?;

          return SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.person, color: Color(0xffffffff), size: 80),
                const Text(
                  "User Details",
                  style: TextStyle(fontFamily: 'Font1', fontSize: 20, color: Colors.white),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 236, 179, 74),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        userInfo("Name", userData?["name"]),
                        divider(),
                        userInfo("Username", userData?["username"]),
                        divider(),
                        userInfo("Age", userData?["age"]),
                        divider(),
                        userInfo("Gender", userData?["gender"]),
                        divider(),
                        userInfo("Email", userData?["email"]),
                        divider(),
                        userInfo("Mobile", userData?["mobile"]),
                        divider(),
                        const Text(
                          "Emergency Contacts:",
                          style: TextStyle(fontFamily: 'Font1', fontSize: 16, color: Color(0xff0C0C0C)),
                        ),
                        ...(userData?["emergencyContacts"] as List<dynamic>? ?? []).map((contact) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              "${contact["name"]}: ${contact["number"]}",
                              style: const TextStyle(
                                fontFamily: 'Font1',
                                fontSize: 16,
                                color: Color(0xff0C0C0C),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget userInfo(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Text(
      "$label: ${value ?? 'N/A'}",
      style: const TextStyle(
        fontFamily: 'Font1',
        fontSize: 16,
        color: Color(0xff0C0C0C),
      ),
    ),
  );
}

Widget divider() {
  return const Divider(color: Color(0xff0C0C0C), thickness: 1);
}
