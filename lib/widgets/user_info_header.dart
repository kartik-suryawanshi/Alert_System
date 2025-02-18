import 'package:flutter/material.dart';
import '../UI/screens/user_profile_page.dart';

class UserInfoHeader extends StatelessWidget {
  final String username;
  final String location;

  const UserInfoHeader({
    Key? key,
    required this.username,
    required this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set display values with fallback for missing data
    final displayUsername = username.isNotEmpty ? username : 'User';
    final displayLocation = location.isNotEmpty ? location : 'Fetching location...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Navigate to User Profile Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(
                        username: displayUsername,
                        location: displayLocation,
                        mobileNumber: '',  // Placeholder for real data
                        email: '',         // Placeholder for real data
                        age: 0,            // Placeholder for real data
                        gender: '',        // Placeholder for real data
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: Colors.purple,
                  radius: 25,
                  child: Text(
                    displayUsername[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi $displayUsername',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    displayLocation,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              // Placeholder for future location-related actions
              print('Location icon tapped');
            },
            icon: const Icon(Icons.location_pin, color: Colors.red, size: 24),
            tooltip: 'Show Location',
          ),
        ],
      ),
    );
  }
}
