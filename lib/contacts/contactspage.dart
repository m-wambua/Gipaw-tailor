// contacts_page.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gipaw_tailor/contacts/contactsmodel.dart';
import 'package:image_picker/image_picker.dart';

class ContactsPage extends StatefulWidget {
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final ContactsManager _contactsManager = ContactsManager();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _businessNatureController = TextEditingController();
  File? _businessCard;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeContacts();
  }

  Future<void> _initializeContacts() async {
    await _contactsManager.initialize();
    setState(() {});
  }

  Future<void> _addContact() async {
    if (_formKey.currentState!.validate()) {
      final contact = Contact(
        id: _contactsManager.generateUuid(),
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        businessNature: _businessNatureController.text,
        email: _emailController.text,
        address: _addressController.text,
        businessCardPath: _businessCard?.path,
      );

      await _contactsManager.addContact(contact);
      setState(() {});
      _clearForm();
    }
  }

  Future<void> _pickBusinessCard() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _businessCard = File(image.path);
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _businessNatureController.clear();
    setState(() {
      _businessCard = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _contactsManager.contacts.length,
              itemBuilder: (context, index) {
                final contact = _contactsManager.contacts[index];
                return Dismissible(
                  key: Key(contact.id),
                  onDismissed: (direction) async {
                    await _contactsManager.deleteContact(contact.id);
                    setState(() {});
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: contact.businessCardPath != null
                          ? Image.file(
                              File(contact.businessCardPath!),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                      title: Text(contact.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact.phoneNumber),
                          if (contact.email != null) Text(contact.email!),
                          if (contact.address != null) Text(contact.address!),
                          Text(contact.businessNature),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Contact'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter a name' : null,
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter a phone number'
                        : null,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  TextFormField(
                    controller: _businessNatureController,
                    decoration:
                        const InputDecoration(labelText: 'Nature of Business'),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter nature of business'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickBusinessCard,
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload Business Card'),
                  ),
                  if (_businessCard != null)
                    Image.file(
                      _businessCard!,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearForm();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _addContact();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _businessNatureController.dispose();
    super.dispose();
  }
}
