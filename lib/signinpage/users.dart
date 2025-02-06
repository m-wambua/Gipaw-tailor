import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String password; // In real app, store hashed password
  final UserRole role;
  final bool? isDisabled;

  User({
    required this.id,
    this.username,
    this.email,
    this.phoneNumber,
    required this.password,
    required this.role,
    this.isDisabled = false,
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
      'isDisabled': isDisabled,
    });
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? phoneNumber,
    String? password,
    UserRole? role,
    bool? isDisabled,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      role: role ?? this.role,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }

  factory User.fromApplication(UserApplication application, UserRole role) {
    return User(
      id: application.id,
      username: application.username,
      email: application.email,
      password: '',
      role: role,
      isDisabled: false,
    );
  }

  // Create User object from JSON string
  factory User.fromJson(Map<
    String,dynamic> json) {
    
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      password: json['password'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => UserRole.user,
      ),
      isDisabled: json['isDisabled'] ?? false,
    );
  }

  static Future<void> saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonUsers = users.map((user) => user.toJson()).toList();
    await prefs.setStringList(
        "active_users", jsonUsers.map((user) => json.encode(user)).toList());
  }

  static Future<List<User>> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonUsers = prefs.getStringList("active_users") ?? [];

    return jsonUsers.map((jsonString) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return User.fromJson(jsonMap);
    }).toList();
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

enum SignInMethod {
  username,
  email,
  phoneNumber,
}

class UserApplication {
  final String id;
  final String username;
  final String email;
  final DateTime applicationDate;

  UserApplication({
    required this.id,
    required this.username,
    required this.email,
    required this.applicationDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'applicationDate': applicationDate.toIso8601String()
      };
  factory UserApplication.fromJson(Map<String, dynamic> json) =>
      UserApplication(
          username: json['username'],
          applicationDate: json['applicationDate'],
          email: json['email'],
          id: json['id']);

  static Future<void> saveApplications(
      List<UserApplication> applications) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonApplications =
        applications.map((application) => application.toJson()).toList();
    await prefs.setStringList(
        'user_application',
        jsonApplications
            .map((application) => json.encode(application))
            .toList());
  }

  static Future<List<UserApplication>> loadApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonApplications = prefs.getStringList('user_application') ?? [];

    return jsonApplications.map((jsonString) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return UserApplication.fromJson(jsonMap);
    }).toList();
  }

  static Future<void> maintainApplications(List<UserApplication> applications,
      {int maxEntires = 500}) async {
    if (applications.length > maxEntires) {
      final trimmedApplications =
          applications.sublist(applications.length - maxEntires);
      await saveApplications(trimmedApplications);
    }
  }
}
