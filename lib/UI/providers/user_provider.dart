import 'package:flutter/material.dart';
import '../models/contact_model.dart';

class UserProvider with ChangeNotifier {
  String _username = "Madhura";
  String _location = "Alan Street, Safe Location";
  List<ContactModel> _emergencyContacts = [];

  // Getters
  String get username => _username;
  String get location => _location;
  List<ContactModel> get emergencyContacts => _emergencyContacts;

  // Setters and Updaters
  void updateUsername(String name) {
    _username = name;
    notifyListeners();
  }

  void updateLocation(String location) {
    _location = location;
    notifyListeners();
  }

  void addEmergencyContact(ContactModel contact) {
    _emergencyContacts.add(contact);
    notifyListeners();
  }

  void removeEmergencyContact(String phone) {
    _emergencyContacts.removeWhere((contact) => contact.phone == phone);
    notifyListeners();
  }
}
