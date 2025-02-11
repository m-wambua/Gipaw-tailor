import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gipaw_tailor/signinpage/authorization.dart';
import 'package:gipaw_tailor/signinpage/protectedroutes.dart';
import 'package:gipaw_tailor/signinpage/users.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashBoard extends StatefulWidget {
  @override
  _AdminDashBoardState createState() => _AdminDashBoardState();
}

class _AdminDashBoardState extends State<AdminDashBoard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
        allowedRoles: [UserRole.admin],
        child: Scaffold(
          appBar: AppBar(
            title: Text("Admin Dashboard"),
            bottom: TabBar(controller: _tabController, tabs: [
              Tab(
                text: "Pending Applications",
              ),
              Tab(
                text: "Active Users",
              ),
              Tab(
                text: "User Activity",
              )
            ]),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              PendingApplicationsTab(),
              ActiveUsersTab(),
              UserActivityTab()
            ],
          ),
        ));
  }
}

class PendingApplicationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final pendingApplications = authProvider.pendingApplications;
    if (pendingApplications.isEmpty) {
      return Center(
        child: Text("No pending applications"),
      );
    }
    return ListView.builder(
        itemCount: pendingApplications.length,
        itemBuilder: (context, index) {
          final application = pendingApplications[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text('Application #${index + 1}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Application from: ${application.firstName} ${application.lastName}"),
                  Text('Username: ${application.username}'),
                  Text("Email: ${application.email}"),
                  Text(
                      "Applied: ${_formatDate(application.applicationDate.toString())}")
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () {
                        _showApprovalDialog(context, index, application);
                      },
                      icon: Icon(
                        Icons.check,
                        color: Colors.green,
                      )),
                  IconButton(
                      onPressed: () {
                        _showRejectionDialog(context, index, application);
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.red,
                      ))
                ],
              ),
            ),
          );
        });
  }

  String _formatDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showApprovalDialog(
      BuildContext context, int index, UserApplication application) {
    UserRole selectedRole = UserRole.user;

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                  title: Text('Approve Application'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Select role for the new user:"),
                      DropdownButton<UserRole>(
                          value: selectedRole,
                          items: UserRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.toString().split('.').last),
                            );
                          }).toList(),
                          onChanged: (UserRole? newRole) {
                            if (newRole != null) {
                              setState(() {
                                selectedRole = newRole;
                              });
                            }
                          })
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel')),
                    TextButton(
                        onPressed: () {
                          final authProvider =
                              Provider.of<AuthProvider>(context, listen: false);
                          authProvider.approveApplication(index, selectedRole);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Application approved successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: Text('Approve'))
                  ],
                )));
  }

  void _showRejectionDialog(
      BuildContext context, int index, UserApplication application) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Reject Application'),
              content: TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: "Rejection Reason",
                  hintText: "Enter reason for rejection",
                ),
                maxLines: 3,
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel')),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                      if (reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter a rejection reason'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      authProvider.rejectApplication(
                          index, reasonController.text.trim());
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Application rejected'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    child: Text("Reject"))
              ],
            ));
  }
}

class ActiveUsersTab extends StatelessWidget {
  final _searchController = TextEditingController();

  // Helper method to check if a user is currently active
  bool isUserActive(String username, List<UserActivity> activities) {
    // Sort activities by timestamp in descending order
    final userActivities = activities
        .where((activity) => activity.username == username)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // If user has no activities, they're not active
    if (userActivities.isEmpty) return false;

    // Check if their most recent activity was a login
    return userActivities.first.actionType.toLowerCase() == 'login';
  }

  // Get unique users from activity log
  List<String> getActiveUsers(List<UserActivity> activities) {
    final uniqueUsers = activities
        .map((activity) => activity.username)
        .toSet()
        .where((username) => isUserActive(username!, activities))
        .toList();
    return uniqueUsers;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final activities = authProvider.userActivities;
    final activeUsers = getActiveUsers(activities);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Users',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              // Implement search if needed
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: activeUsers.length,
            itemBuilder: (context, index) {
              final username = activeUsers[index];
              // Get last activity time for this user
              final lastActivity = activities
                  .where((activity) => activity.username == username)
                  .reduce(
                      (a, b) => a.timestamp.compareTo(b.timestamp) > 0 ? a : b);

              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(username[0].toUpperCase()),
                  ),
                  title: Text(username),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Active: ${lastActivity.timestamp}'),
                      Text('Status: Active'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'disable',
                        child: ListTile(
                          leading: Icon(Icons.block),
                          title: Text('Force Logout'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'activity',
                        child: ListTile(
                          leading: Icon(Icons.history),
                          title: Text('View Activity'),
                        ),
                      ),
                      PopupMenuItem(
                          value: "delete",
                          child: ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('delete account'),
                          ))
                    ],
                    onSelected: (value) async {
                      switch (value) {
                        case 'disable':
                          _showForceLogoutDialog(context, username);
                          break;
                        case 'activity':
                          _showUserActivityDialog(
                              context, username, activities);
                        case 'delete':
                          _showDeleteAccountDialog(context, index);
                          break;
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showForceLogoutDialog(BuildContext context, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Force Logout User'),
        content: Text('Are you sure you want to force logout this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () async {
              // Add a logout activity
              final newActivity = UserActivity(
                username: username,
                timestamp: DateTime.now().toIso8601String(),
                actionType: 'Logout (Forced by Admin)',
              );

              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              authProvider.addUserActivity(newActivity);
              Navigator.pop(context);
            },
            child: Text('Force Logout'),
          ),
        ],
      ),
    );
  }

  void _showUserActivityDialog(
      BuildContext context, String username, List<UserActivity> allActivities) {
    final userActivities = allActivities
        .where((activity) => activity.username == username)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Activity History - $username'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: userActivities.length,
            itemBuilder: (context, index) {
              final activity = userActivities[index];
              return ListTile(
                leading: Icon(
                  activity.actionType.toLowerCase() == 'login'
                      ? Icons.login
                      : Icons.logout,
                ),
                title: Text(activity.actionType),
                subtitle: Text(activity.timestamp),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, int index) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("Delete Account"),
              content: Text("Are you sure you want to delete your account?"),
              actions: [
                TextButton(
                    onPressed: () async {
                      //   await _deleteAccount(index);
                      Navigator.pop(context);
                    },
                    child: Text("Yes")),
                TextButton(
                    onPressed: () => Navigator.pop(context), child: Text("No")),
              ],
            ));
  }
}

class UserActivityTab extends StatelessWidget {
  // Helper method to format timestamp
  String _formatTimestamp(String timestamp) {
    final DateTime dateTime = DateTime.parse(timestamp);
    return DateFormat('MMM d, y h:mm a').format(dateTime);
  }

  // Helper method to get appropriate icon for action type
  IconData _getActionIcon(String actionType) {
    if (actionType.toLowerCase().contains('login')) {
      return Icons.login;
    } else if (actionType.toLowerCase().contains('logout')) {
      return Icons.logout;
    } else if (actionType.toLowerCase().contains('approved')) {
      return Icons.check_circle;
    } else if (actionType.toLowerCase().contains('rejected')) {
      return Icons.cancel;
    } else if (actionType.toLowerCase().contains('disabled')) {
      return Icons.block;
    } else if (actionType.toLowerCase().contains('deleted')) {
      return Icons.delete;
    } else if (actionType.toLowerCase().contains('role')) {
      return Icons.assignment_ind;
    } else {
      return Icons.info;
    }
  }

  // Helper method to get color for action type
  Color _getActionColor(String actionType) {
    if (actionType.toLowerCase().contains('login')) {
      return Colors.green;
    } else if (actionType.toLowerCase().contains('logout')) {
      return Colors.blue;
    } else if (actionType.toLowerCase().contains('approved')) {
      return Colors.green;
    } else if (actionType.toLowerCase().contains('rejected')) {
      return Colors.red;
    } else if (actionType.toLowerCase().contains('disabled')) {
      return Colors.orange;
    } else if (actionType.toLowerCase().contains('deleted')) {
      return Colors.red;
    } else if (actionType.toLowerCase().contains('role')) {
      return Colors.purple;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final activities = authProvider.userActivities;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Activity',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 8),
              PopupMenuButton(
                icon: Icon(Icons.filter_list),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text('Last 24 Hours'),
                    value: '24h',
                  ),
                  PopupMenuItem(
                    child: Text('Last 7 Days'),
                    value: '7d',
                  ),
                  PopupMenuItem(
                    child: Text('Last 30 Days'),
                    value: '30d',
                  ),
                ],
                onSelected: (value) {
                  // Handle filter selection
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: activities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No activity records found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getActionColor(activity.actionType)
                              .withOpacity(0.1),
                          child: Icon(
                            _getActionIcon(activity.actionType),
                            color: _getActionColor(activity.actionType),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                activity.username,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              _formatTimestamp(activity.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            activity.actionType,
                            style: TextStyle(
                              color: _getActionColor(activity.actionType),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class UserActivity {
  final String username;
  final String actionType;
  final String timestamp;

  UserActivity(
      {required this.username,
      required this.timestamp,
      required this.actionType});

  Map<String, dynamic> toJson() =>
      {"username": username, 'actionType': actionType, 'timestamp': timestamp};

  factory UserActivity.fromJson(Map<String, dynamic> json) => UserActivity(
      username: json['username'],
      timestamp: json['timestamp'],
      actionType: json['actionType']);

  static Future<void> saveActivities(List<UserActivity> activities) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonActivities =
        activities.map((activity) => activity.toJson()).toList();
    await prefs.setStringList('user_activities',
        jsonActivities.map((activity) => json.encode(activity)).toList());
  }

  static Future<List<UserActivity>> loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final savedActivities = prefs.getStringList('user_activities') ?? [];

    return savedActivities.map((jsonString) {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return UserActivity.fromJson(jsonMap);
    }).toList();
  }

  static Future<void> maintainActivityLog(List<UserActivity> activities,
      {int maxEntries = 500}) async {
    if (activities.length > maxEntries) {
      final trimmedActivites =
          activities.sublist(activities.length - maxEntries);
      await saveActivities(trimmedActivites);
    }
  }
}
