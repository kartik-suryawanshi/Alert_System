import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(), // Floating Button Cutout
      notchMargin: 0, // Space around the notch
      color: Color(0xff312F2F), // Bottom Nav Background
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: buildNavItem(Icons.person_add, "Attendant", 1),
            ), // 🟢 Fixed to `1`
            Expanded(child: buildNavItem(Icons.location_pin, "Location", 2)),
            SizedBox(width: 40), // Space for FAB
            Expanded(child: buildNavItem(Icons.chat_outlined, "ChatBox", 3)),
            Expanded(child: buildNavItem(Icons.person, "Profile", 4)),
          ],
        ),
      ),
    );
  }

  Widget buildNavItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => onTabSelected(index),
      splashColor: Colors.orange.withOpacity(0.3),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: currentIndex == index ? Colors.orange : Colors.white,
            size: 26,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Font1',
              color: currentIndex == index ? Color(0xffFFA500) : Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}