import 'package:gipaw_tailor/signinpage/users.dart';

class SignUpApplication {
  final String id;
  final String username;
  final String? email;
  final String? phoneNumber;
  final DateTime applicationDate;
  final bool isPending;

  SignUpApplication({
    required this.id,
    required this.username,
    this.email,
    this.phoneNumber,
    required this.applicationDate,
    required this.isPending,
  });
}

class UserDetails extends User {
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;

  UserDetails({
    required String id,
    String? username,
    String? email,
    String? phoneNumber,
    required UserRole role,
    required String password,
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
  }) : super(
            id: id,
            username: username,
            email: email,
            phoneNumber: phoneNumber,
            role: role,
            password: password);
}
