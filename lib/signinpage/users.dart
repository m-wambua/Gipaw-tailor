import 'dart:convert';

import 'package:html/parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String? password; // In real app, store hashed password
  final UserRole? role;
  final bool? isDisabled;
  final bool? isActive;
  final UserStatus status;

  User(
      {required this.id,
      this.username,
      this.email,
      this.phoneNumber,
      this.password,
      this.role,
      this.isDisabled = false,
      this.isActive = true,
      this.status=UserStatus.pending
      }
      
      );

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
      'status':status.toString()
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
    UserStatus? status,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      role: role ?? this.role,
      isDisabled: isDisabled ?? this.isDisabled,
      status: status ?? this.status,
    );
  }

  factory User.fromApplication(UserApplication application, UserRole role) {
    return User(
      id: application.id,
      username: application.username,
      email: application.email,
      phoneNumber: application.phoneNumber,
      password: application.password, // Now using the password from application
      role: role,
      isDisabled: false,
      isActive: true,
      status: UserStatus.pending
    );
  }

  // Create User object from JSON string
  factory User.fromJson(Map<String, dynamic> json) {
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
      status: UserStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => UserStatus.pending,
        ),
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

enum UserStatus { pending, approved, rejected }

enum SignInMethod {
  username,
  email,
  phoneNumber,
}

class UserApplication {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String password;
  final DateTime applicationDate;

  UserApplication({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.password,
    required this.applicationDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'password': password,
        'applicationDate': applicationDate.toIso8601String()
      };
  factory UserApplication.fromJson(Map<String, dynamic> json) =>
      UserApplication(
          username: json['username'],
          applicationDate: DateTime.parse(json['applicationDate']),
          email: json['email'],
          firstName: json['firstName'],
          lastName: json['lastName'],
          phoneNumber: json['phoneNumber'],
          password: json['password'],
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
