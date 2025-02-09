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
  List<UserApplication> _applications = [];
  List<User> get activeUsers =>
      _users.where((user) => user.isActive ?? false).toList();

  // Return the list of active users
  AuthProvider() {
    _loadSavedActivities();
    _loadSavedApplications();
    _loadUsers();
    loadPendingApplications();
  }

  Future<void> loadPendingApplications() async {
    _pendingApplications = await UserApplication.loadApplications();
    notifyListeners();
  }

  Future<void> _loadUsers() async {
    _users = await User.loadUsers();
    notifyListeners();
  }

  Future<void> _loadSavedApplications() async {
    _applications = await UserApplication.loadApplications();
    notifyListeners();
  }

  Future<void> _loadSavedActivities() async {
    _userActivities = await UserActivity.loadActivities();
    notifyListeners();
  }

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

      //  final usersJson = prefs.getStringList('users') ?? [];
      //  final users = usersJson.map((json) => User.fromJson(json)).toList();

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

  void logUserActivity(String username, String actionType) async {
    final newActivity = (UserActivity(
        username: username,
        timestamp: DateTime.now().toIso8601String(),
        actionType: actionType));
    _userActivities.add(newActivity);

    await UserActivity.saveActivities(_userActivities);

    await UserActivity.maintainActivityLog(_userActivities);
    notifyListeners();
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

  void updateUserRole(User user, UserRole newRole) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = User(
          id: _users[index].id,
          password: _users[index].password,
          role: newRole,
          isDisabled: _users[index].isDisabled,
          email: _users[index].email,
          phoneNumber: _users[index].phoneNumber,
          username: _users[index].username);
      await User.saveUsers(_users);

      user.copyWith(role: newRole);
      logUserActivity(
          user.username ?? 'Unknown', 'Role Changed to ${newRole.toString()}');
      notifyListeners();
    }
  }

  Future<void> toggleUserStatus(String userId) async {
    final userIndex = _users.indexWhere((user) => user.id == userId);
    if (userIndex != -1) {
      _users[userIndex] = User(
        id: _users[userIndex].id,
        username: _users[userIndex].username,
        email: _users[userIndex].email,
        role: _users[userIndex].role,
        isDisabled: _users[userIndex].isDisabled,
        phoneNumber: _users[userIndex].phoneNumber,
        password: _users[userIndex].password,
      );
      await User.saveUsers(_users);
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

  void deleteUser(User user) async {
    _users.removeWhere((u) => u.id == user.id);
    logUserActivity(user.username ?? 'Unknown', 'Account Deleted');
    await User.saveUsers(_users);
    notifyListeners();
  }

  void addUserActivity(UserActivity activity) async {
    userActivities.add(activity);
    await UserActivity.saveActivities(userActivities);
    notifyListeners();
  }

  Future<void> addPendingApplication(UserApplication application) async {
    // Load existing applications
    final applications = await UserApplication.loadApplications();

    // Add new application
    _pendingApplications.add(application);

    // Save updated applications
    await UserApplication.saveApplications(_pendingApplications);

    // Update the pending applications list
    _pendingApplications = applications;

    // Maintain applications (trim if exceeds max)
    await UserApplication.maintainApplications(_pendingApplications);

    notifyListeners();
  }

  Future<void> approveApplication(int index, UserRole role) async {
    final application = _pendingApplications[index];

    // Create new user from application
    final user = User.fromApplication(application, role);

    // Save the new user
    await saveNewUser(user);
    final activity = UserActivity(
        username: application.username,
        actionType: "Account Approved",
        timestamp: DateTime.now().toIso8601String());
    userActivities.add(activity);
    await UserActivity.saveActivities(userActivities);

    // Remove from pending applications
    _pendingApplications.removeAt(index);
    await UserApplication.saveApplications(_pendingApplications);

    notifyListeners();
  }

  Future<void> rejectApplication(int index, String reason) async {
    // Remove from pending applications
    final application = _pendingApplications[index];
    final activity = UserActivity(
        username: application.username,
        actionType: "Application Rejected: $reason",
        timestamp: DateTime.now().toIso8601String());
        userActivities.add(activity);
        await UserActivity.saveActivities(userActivities);
    _pendingApplications.removeAt(index);
    await UserApplication.saveApplications(_pendingApplications);

    notifyListeners();
  }
}
