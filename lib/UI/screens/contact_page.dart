import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsPage extends StatefulWidget {
  final List<Map<String, String>> emergencyContacts;

  const ContactsPage({Key? key, required this.emergencyContacts})
      : super(key: key);

  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  String _searchQuery = "";
  List<Map<String, String>> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _emergencyContacts = List.from(widget.emergencyContacts);
    _getContacts();
  }

  Future<void> _getContacts() async {
    var permissionStatus = await Permission.contacts.request();
    if (permissionStatus.isGranted) {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission to access contacts denied!')),
      );
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filteredContacts = _contacts
          .where((contact) =>
      contact.displayName != null &&
          contact.displayName!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _addToEmergencyContacts(Contact contact) {
    if (contact.phones.isNotEmpty) {
      final emergencyContact = {
        'name': contact.displayName ?? 'Unnamed',
        'number': contact.phones.first.number ?? 'No phone number',
      };

      setState(() {
        _emergencyContacts.add(emergencyContact);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${emergencyContact['name']} added to emergency contacts!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No phone number found for ${contact.displayName}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _emergencyContacts);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: _filteredContacts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                return ListTile(
                  title: Text(contact.displayName ?? 'Unnamed'),
                  subtitle: contact.phones.isNotEmpty
                      ? Text(contact.phones.first.number ?? 'No phone number')
                      : const Text('No phone number'),
                  onTap: () => _addToEmergencyContacts(contact),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
