import 'package:flutter/material.dart';
import 'package:gipaw_tailor/signinpage/protectedroutes.dart';
import 'package:gipaw_tailor/signinpage/users.dart';

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
    return ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text('Application #${index + 1}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Username: user_${index + 1}'),
                  Text("Email: user_${index + 1}@example.com"),
                  Text("Applied: ${DateTime.now().toString()}")
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
            itemCount: 20, // Replace with actual users count
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('U${index + 1}'),
                  ),
                  title: Text('User ${index + 1}'),
                  subtitle: Text(
                      'Role: ${UserRole.values[index % 3].toString().split('.').last}'),
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
            itemCount: 50, // Replace with actual activity count
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text('User Action ${index + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User: user_${index + 1}'),
                      Text('Action: ${index % 2 == 0 ? "Login" : "Logout"}'),
                      Text(
                          'Time: ${DateTime.now().subtract(Duration(minutes: index)).toString()}'),
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
