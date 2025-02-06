import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gipaw_tailor/signinpage/authorization.dart';
import 'package:gipaw_tailor/signinpage/protectedroutes.dart';
import 'package:gipaw_tailor/signinpage/users.dart';
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
                  Text('Username: ${application.username}'),
                  Text("Email: user_${application.email}"),
                  Text("Applied: ${application.applicationDate}")
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () {
                        _showApprovalDialog(context, index);
                      },
                      icon: Icon(
                        Icons.check,
                        color: Colors.green,
                      )),
                  IconButton(
                      onPressed: () {
                        _showRejectionDialog(context, index);
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

  void _showApprovalDialog(BuildContext context, int index) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Approve Application'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Select role for the new user:"),
                  DropdownButton<UserRole>(
                      value: UserRole.user,
                      items: UserRole.values.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (UserRole? newRole) {
                        //Handle role selection
                      })
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Approve'))
              ],
            ));
  }

  void _showRejectionDialog(BuildContext context, int index) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Reject Application'),
              content: TextField(
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
                      Navigator.pop(context);
                    },
                    child: Text("Reject"))
              ],
            ));
  }
}

class ActiveUsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final users = authProvider.activeUsers;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Search Users',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: users.length, // Replace with actual users count
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('U${index + 1}'),
                  ),
                  title: Text(user.username ?? 'No Username'),
                  subtitle: Text('Role: ${user.role}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit Role'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'disable',
                        child: ListTile(
                          leading: Icon(Icons.block),
                          title: Text('Disable Account'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete Account'),
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditRoleDialog(context, index);
                          break;
                        case 'disable':
                          _showDisableAccountDialog(context, index);
                          break;
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

  void _showEditRoleDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit User Role'),
        content: DropdownButton<UserRole>(
          value: UserRole.user,
          items: UserRole.values.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role.toString().split('.').last),
            );
          }).toList(),
          onChanged: (UserRole? newRole) {
            // Handle role change
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update user role
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDisableAccountDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disable Account'),
        content: Text('Are you sure you want to disable this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            onPressed: () {
              // Disable account
              Navigator.pop(context);
            },
            child: Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content:
            Text('Are you sure you want to permanently delete this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              // Delete account
              Navigator.pop(context);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class UserActivityTab extends StatelessWidget {
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
          child: ListView.builder(
            itemCount: activities.length, // Replace with actual activity count
            itemBuilder: (context, index) {
              final activity = activities[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text('User Action ${index + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User: ${activity.username}'),
                      Text('Action: ${index % 2 == 0 ? "Login" : "Logout"}'),
                      Text('Time: ${activity.timestamp}'),
                    ],
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
