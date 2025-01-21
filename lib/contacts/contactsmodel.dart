import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class Contact {
  final String id;
  final String name;
  final String phoneNumber;
  final String businessNature;
  String? email;
  String? address;
  String? businessCardPath;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.businessNature,
    this.email,
    this.address,
    this.businessCardPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
    'email': email,
    'address': address,
    'businessNature': businessNature,
    'businessCardPath': businessCardPath,
  };

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      businessNature: json['businessNature'],
      email: json['email'],
      address: json['address'],
      businessCardPath: json['businessCardPath'],
    );
  }
}



class ContactsManager {
  static final ContactsManager _instance = ContactsManager._internal();
  factory ContactsManager() => _instance;
  ContactsManager._internal();

  List<Contact> _contacts = [];
  late String _filePath;
  final _uuid = const Uuid();

  List<Contact> get contacts => List.unmodifiable(_contacts);

  Future<void> initialize() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath = '${directory.path}/contacts.json';
    await loadContacts();
  }

  Future<void> loadContacts() async {
    try {
      final file = File(_filePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        _contacts = jsonList.map((json) => Contact.fromJson(json)).toList();
        print('Loaded ${_contacts.length} contacts from file');
      }
    } catch (e) {
      print('Error loading contacts: $e');
      _contacts = [];
    }
  }

  Future<void> saveContacts() async {
    try {
      final file = File(_filePath);
      final jsonString = json.encode(_contacts.map((contact) => contact.toJson()).toList());
      await file.writeAsString(jsonString);
      print('Saved ${_contacts.length} contacts to file');
    } catch (e) {
      print('Error saving contacts: $e');
      throw Exception('Failed to save contacts');
    }
  }

  Future<void> addContact(Contact contact) async {
    _contacts.add(contact);
    await saveContacts();
  }

  Future<void> updateContact(Contact contact) async {
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _contacts[index] = contact;
      await saveContacts();
    }
  }

  Future<void> deleteContact(String id) async {
    _contacts.removeWhere((contact) => contact.id == id);
    await saveContacts();
  }

  String generateUuid() => _uuid.v4();
}
