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
  @override
  final bool isActive;

  UserDetails({
    required super.id,
    super.username,
    super.email,
    super.phoneNumber,
    required UserRole super.role,
    required String super.password,
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
  });
}
