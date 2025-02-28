import 'package:flutter/material.dart';
import 'package:gipaw_tailor/signinpage/authorization.dart';
import 'package:gipaw_tailor/signinpage/users.dart';
import 'package:provider/provider.dart';

class ProtectedRoutes {
  static final Map<String, List<UserRole>> routePermissions = {
    '/sell-uniform': [UserRole.admin, UserRole.manager, UserRole.user],
    '/sell-curtains': [UserRole.admin, UserRole.manager, UserRole.user],
    '/sell-new-clothes': [UserRole.admin, UserRole.manager, UserRole.user],
    '/view-stock': [UserRole.admin, UserRole.manager],
    '/sales': [UserRole.admin, UserRole.manager],
    '/reminders': [UserRole.admin, UserRole.manager],
    '/contacts': [UserRole.admin, UserRole.manager],
    '/sales-summary': [UserRole.admin, UserRole.manager],
    '/admin-dashboard':[UserRole.admin]
  };
}

class ProtectedNavigationButton extends StatelessWidget {
  final String text;
  final List<UserRole> allowedRoles;
  final VoidCallback onPressed;

  const ProtectedNavigationButton({
    super.key,
    required this.text,
    required this.allowedRoles,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, auth, child) {
      final bool hasAccess = auth.hasPermission(allowedRoles);
      return TextButton(
          onPressed: hasAccess
              ? onPressed
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('You do not have permission to access this page'),
                    backgroundColor: Colors.red,
                  ));
                },
          style: TextButton.styleFrom(
            foregroundColor: hasAccess ? null : Colors.grey,
          ),
          child: Text(text));
    });
  }
}

class ProtectedRoute extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;

  const ProtectedRoute({super.key, 
    required this.allowedRoles,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.hasPermission(allowedRoles)) {
          // Redirect to sign in or show access denied
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You don\'t have permission to access this page'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}