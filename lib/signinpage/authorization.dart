import 'package:flutter/material.dart';
import 'package:gipaw_tailor/main.dart';
import 'package:gipaw_tailor/signinpage/admindash.dart';
import 'package:gipaw_tailor/signinpage/users.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  User? get currentUser => _currentUser;
  List<UserActivity> _userActivities = [];
  List<UserActivity> get userActivities => _userActivities;
  List<User> _users = [];
  List<User> get users => _users;
  List<UserApplication> _pendingApplications = [];
  List<UserApplication> get pendingApplications => _pendingApplications;

  List<User> get activeUsers =>
      _users.where((user) => user.isDisabled != null && !user.isDisabled!).toList();
  // Return the list of active users

  Future<bool> signIn(
      String identifier, String password, SignInMethod method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminUsername = prefs.getString('admin_username');
      final adminPassowrd = prefs.getString("Summerday1998");

      if ((method == SignInMethod.username && identifier == adminUsername) ||
          (method == SignInMethod.email && identifier == adminUsername)) {
        if (password == adminPassowrd) {
          _currentUser = User(
              id: 'admin',
              role: UserRole.admin,
              password: adminPassowrd ?? '',
              email: adminUsername,
              username: adminUsername);
          logUserActivity(adminUsername!, 'Login');

          notifyListeners();
          return true;
        }
      }

      final usersJson = prefs.getStringList('users') ?? [];
      final users = usersJson.map((json) => User.fromJson(json)).toList();

      final matchingUser = users.firstWhere(
        (user) {
          switch (method) {
            case SignInMethod.username:
              return user.username == identifier;
            case SignInMethod.email:
              return user.email == identifier;
            case SignInMethod.phoneNumber:
              return user.phoneNumber == identifier;
          }
        },
        orElse: () => User(
            id: '',
            username: '',
            role: UserRole.user,
            password: '',
            email: '',
            phoneNumber: ''),
      );
      if (matchingUser != null) {
        if (matchingUser.password == password) {
          _currentUser = matchingUser;
          logUserActivity(identifier, 'Login');

          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error during sign in : $e");
      return false;
    }
  }

  void handleApplication(UserApplication application, bool approved,
      {UserRole? role, String? rejectionReason}) {
    if (approved) {
      _users.add(User.fromApplication(application, role ?? UserRole.user));
      logUserActivity(application.username, 'Account Approved');
    } else {
      logUserActivity(application.username, 'Application Rejected');
    }
    _pendingApplications.removeWhere((a) => a.id == application.id);
    notifyListeners();
  }

  void logUserActivity(String username, String actionType) {
    _userActivities.add(UserActivity(
        username: username,
        timestamp: DateTime.now().toIso8601String(),
        actionType: actionType));
  }

  void signOut() {
    if (_currentUser != null) {
      logUserActivity(_currentUser!.username ?? 'Unknown', 'Logout');
    }
    _currentUser = null;
    notifyListeners();
  }

  bool hasPermission(List<UserRole> allowedRoles) {
    if (_currentUser == null) {
      return false;
    }
    return allowedRoles.contains(_currentUser!.role);
  }

  void updateUserRole(User user, UserRole newRole) {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user.copyWith(role: newRole);
      logUserActivity(
          user.username ?? 'Unknown', 'Role Changed to ${newRole.toString()}');
      notifyListeners();
    }
  }

  Future<void> initializeAdmin({
    required String username,
    required String password,
  }) async {
    // Initialize admin user in your storage system
    // This could be a local database, API call, etc.
    _currentUser = User(
        id: 'admin',
        username: username,
        role: UserRole.admin,
        password: ADMIN_PASSWORD_KEY);

    // Store admin credentials securely
    // In a real app, you'd want to hash the password
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ADMIN_USERNAME_KEY, username);
    await prefs.setString(ADMIN_PASSWORD_KEY, password);

    notifyListeners();
  }

  // Add this method to validate admin credentials
  Future<bool> validateAdminCredentials(
      String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUsername = prefs.getString(ADMIN_USERNAME_KEY);
    final storedPassword = prefs.getString(ADMIN_PASSWORD_KEY);

    return username == storedUsername && password == storedPassword;
  }

  void disableUser(User user) {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != 1) {
      _users[index] = user.copyWith(isDisabled: true);
      logUserActivity(user.username ?? 'Unknown', "Account Diasbled");
      notifyListeners();
    }
  }

  void deleteUser(User user) {
    _users.removeWhere((u) => u.id == user.id);
    logUserActivity(user.username ?? 'Unknown', 'Account Deleted');
    notifyListeners();
  }
}
