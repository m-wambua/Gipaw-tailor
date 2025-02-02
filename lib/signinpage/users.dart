import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String password; // In real app, store hashed password
  final UserRole role;

  User({
    required this.id,
    this.username,
    this.email,
    this.phoneNumber,
    required this.password,
    required this.role,
  });

  // Convert User object to JSON string
  String toJson() {
    return json.encode({
      'id': id,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password, // In real app, this should be hashed
      'role': role.toString(),
    });
  }

  // Create User object from JSON string
  factory User.fromJson(String jsonString) {
    final data = json.decode(jsonString);
    return User(
      id: data['id'],
      username: data['username'],
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      password: data['password'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == data['role'],
        orElse: () => UserRole.user,
      ),
    );
  }
}

// Helper function to save a new user
Future<void> saveNewUser(User user) async {
  final prefs = await SharedPreferences.getInstance();
  final users = prefs.getStringList('users') ?? [];
  users.add(user.toJson());
  await prefs.setStringList('users', users);
}

enum UserRole {
  admin,
  user,
  manager,
}

enum SignInMethod{
  username,
  email,
  phoneNumber,
}

