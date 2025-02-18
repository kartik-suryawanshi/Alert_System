import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'contact_page.dart';
import 'package:geolocator/geolocator.dart';

class UserProfilePage extends StatefulWidget {
  final String username;
  final String location;
  final String mobileNumber;
  final String email;
  final int age;
  final String gender;
  final String? profileImage; // Profile image URL from Firestore
  final List<Map<String, String>> initialEmergencyContacts;

  const UserProfilePage({
    Key? key,
    required this.username,
    required this.location,
    required this.mobileNumber,
    required this.email,
    required this.age,
    required this.gender,
    this.profileImage, // Optional profile image URL
    this.initialEmergencyContacts = const [],
  }) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late String _username;
  File? _profileImage;
  final TextEditingController _usernameController = TextEditingController();
  final String _userId = FirebaseAuth.instance.currentUser!.uid; // Get logged-in user's ID
  List<Map<String, String>> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _username = widget.username;
    _usernameController.text = _username;
    _emergencyContacts = List.from(widget.initialEmergencyContacts);

    _loadUserData();
  }

  // Load user data from Firestore
Future<void> _loadUserData() async {
  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
    if (doc.exists && mounted) {
      setState(() {
        _username = doc.data()?['username'] ?? widget.username;
        _usernameController.text = _username;

        // Handle emergency contacts safely
        var emergencyContactsData = doc.data()?['emergencyContacts'];
        if (emergencyContactsData != null) {
          _emergencyContacts = List<Map<String, String>>.from(
            emergencyContactsData.map((contact) => Map<String, String>.from(contact)),
          );
        } else {
          _emergencyContacts = [];
        }
      });
    }
  } catch (e) {
    if (mounted) { 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }
}

  // Save new username to Firestore
  Future<void> _saveUsername(String newUsername) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(_userId).set(
      {'username': newUsername},
      SetOptions(merge: true),
    );

    if (mounted) {
      setState(() {
        _username = newUsername;
      });

      Navigator.pop(context, newUsername);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully!')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving username: $e')),
      );
    }
  }
}


  // Upload profile image to Firebase Storage
  Future<void> _uploadProfileImage(File imageFile) async {
    final ref = FirebaseStorage.instance.ref().child('profile_images/$_userId.jpg');
    await ref.putFile(imageFile);
    final imageUrl = await ref.getDownloadURL();

    // Save profile image URL to Firestore
    await FirebaseFirestore.instance.collection('users').doc(_userId).set(
      {'profileImage': imageUrl},
      SetOptions(merge: true),
    );
  }

  // Save profile image to Firestore and local state
  Future<void> _saveProfileImage(File imageFile) async {
    try {
      await _uploadProfileImage(imageFile);
      setState(() {
        _profileImage = imageFile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile picture: $e')));
    }
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _saveProfileImage(File(pickedFile.path));
    }
  }

  // Edit username in a dialog
  void _editUsername(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Username'),
          content: TextField(
            controller: _usernameController,
            decoration: const InputDecoration(hintText: 'Enter your username'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final newUsername = _usernameController.text.trim();
                if (newUsername.isNotEmpty) {
                  _saveUsername(newUsername);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Display emergency contacts
  void _showEmergencyContacts() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Emergency Contacts'),
          content: _emergencyContacts.isEmpty
              ? const Text('No emergency contacts added.')
              : SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _emergencyContacts.length,
              itemBuilder: (context, index) {
                final contact = _emergencyContacts[index];
                return ListTile(
                  title: Text(contact['name']!),
                  subtitle: Text(contact['number']!),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeContact(index),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Remove a contact from the list and database
  Future<void> _removeContact(int index) async {
    final removedContact = _emergencyContacts[index];
    setState(() {
      _emergencyContacts.removeAt(index);
    });

    // Remove from Firestore
    await FirebaseFirestore.instance.collection('users').doc(_userId).set(
      {'emergencyContacts': _emergencyContacts},
      SetOptions(merge: true),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed contact: ${removedContact['name']}')),
    );
  }

  // Navigate to the contacts page
  void _navigateToContactsPage() async {
    final updatedContacts = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactsPage(emergencyContacts: _emergencyContacts),
      ),
    );

    if (updatedContacts != null && updatedContacts is List<Map<String, String>>) {
      setState(() {
        _emergencyContacts = updatedContacts;
      });

      // Save updated contacts to Firestore
      await FirebaseFirestore.instance.collection('users').doc(_userId).set(
        {'emergencyContacts': _emergencyContacts},
        SetOptions(merge: true),
      );
    }
  }

  // Build action cards for the profile page
  Widget _buildActionCard(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Logout method
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // After logging out, navigate to the login page
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surakshini'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (widget.profileImage != null && widget.profileImage!.isNotEmpty
                        ? NetworkImage(widget.profileImage!) as ImageProvider<Object> // Explicit casting here
                        : null),

                    child: _profileImage == null && widget.username.isNotEmpty
                        ? Text(
                      _username[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editUsername(context),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildActionCard(context, Icons.history, 'History', () {}),
                  _buildActionCard(
                    context,
                    Icons.contacts,
                    'Contacts',
                    _navigateToContactsPage,
                  ),
                  _buildActionCard(
                    context,
                    Icons.list,
                    'Emergency List',
                    _showEmergencyContacts,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
