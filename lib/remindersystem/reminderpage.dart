import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gipaw_tailor/remindersystem/reminderclass.dart';
import 'package:intl/intl.dart';

class ReminderPage extends StatefulWidget {
  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ReminderManager _reminderManager;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reminderManager = ReminderManager(
        reminderFilePath: 'lib/remindersystem/reminders.json',
        embroideryFilePath: 'lib/remindersystem/embroidery.json');
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

   Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Wait for both reminders and embroidery items to load
      await _reminderManager.initialize();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reminders & Tracking"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Reminders'),
            Tab(text: 'Embroidery'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRemindersTab(),
          _buildEmbroideryTab(),
          _buildCustomTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog();
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildRemindersTab() {
    return ListView.builder(
      itemCount: _reminderManager.reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminderManager.reminders[index];
        if (reminder.type == ReminderType.stockAlert ||
            reminder.type == ReminderType.customReminder) {
          return _buildReminderCard(reminder);
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildEmbroideryTab() {
    return Column(
      children: [
        _buildEmbroideryStats(),
        Expanded(
            child: ListView.builder(
          itemCount: _reminderManager.embroideries.length,
          itemBuilder: (context, index) {
            return _buildEmbroideryCard(_reminderManager.embroideries[index]);
          },
        ))
      ],
    );
  }

  Widget _buildCustomTab() {
    return ListView.builder(
      itemCount: _reminderManager.reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminderManager.reminders[index];
        if (reminder.type == ReminderType.customReminder) {
          return _buildReminderCard(reminder);
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildEmbroideryStats() {
    final pending = _reminderManager.embroideries
        .where((element) => element.status == EmbroideryStatus.pending)
        .length;
    final inProgress = _reminderManager.embroideries
        .where((element) => element.status == EmbroideryStatus.inProgress)
        .length;

    final completed = _reminderManager.embroideries
        .where((element) => element.status == EmbroideryStatus.completed)
        .length;

    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard('Pending', pending.toString(), Colors.orange),
            _buildStatCard('In Progress', inProgress.toString(), Colors.blue),
            _buildStatCard('Completed', completed.toString(), Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildReminderCard(ReminderItem reminder) {
    final IconData icon;
    final Color color;
    switch (reminder.type) {
      case ReminderType.stockAlert:
        icon = Icons.warning;
        color = Colors.red;
        break;
      case ReminderType.customReminder:
        icon = Icons.notes;
        color = Colors.blue;
        break;
      default:
        icon = Icons.circle;
        color = Colors.grey;
    }
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(reminder.title),
          subtitle: Text(reminder.description),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!reminder.isResolved)
                IconButton(
                    onPressed: () async {
                      reminder.isResolved = true;
                      await _reminderManager.saveReminders();
                      setState(() {});
                    },
                    icon: Icon(Icons.check)),
              IconButton(
                  onPressed: () async {
                    _reminderManager.reminders.remove(reminder);
                    await _reminderManager.saveReminders();
                    setState(() {});
                  },
                  icon: Icon(Icons.delete))
            ],
          )),
    );
  }

  Widget _buildEmbroideryCard(EmbroideryItem item) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Text("${item.uniformItem}- ${item.quantity} pieces"),
        subtitle: Text("sent to ${item.shopName}"),
        trailing: _buildStatusChip(item.status),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Color: ${item.color}"),
                Text("Size: ${item.size}"),
                Text(
                    "Sent Date: ${DateFormat('yyyy-MM-dd').format(item.sentDate)}"),
                if (item.returnDate != null)
                  Text(
                      "Return Date: ${DateFormat('yyyy-MM-dd').format(item.returnDate!)}"),
                if (item.notes != null) Text("Notes: ${item.notes ?? ''}"),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatusButton(item, EmbroideryStatus.inProgress),
                    _buildStatusButton(item, EmbroideryStatus.completed),
                    _buildStatusButton(item, EmbroideryStatus.returned)
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusChip(EmbroideryStatus status) {
    final color = {
      EmbroideryStatus.pending: Colors.orange,
      EmbroideryStatus.inProgress: Colors.blue,
      EmbroideryStatus.completed: Colors.green,
      EmbroideryStatus.returned: Colors.grey,
    }[status]!;

    return Chip(
      label: Text(
        status.toString().split('.').last,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildStatusButton(EmbroideryItem item, EmbroideryStatus status) {
    return TextButton(
      onPressed: item.status.index >= status.index
          ? null
          : () async {
              await _reminderManager.updateEmbroideryStatus(item.id, status);

              if (status == EmbroideryStatus.returned) {
                item.returnDate = DateTime.now();
              }
              await _reminderManager.saveEmbroideryItems();
              setState(() {});
            },
      child: Text(status.toString().split('.').last),
    );
  }

  void _showAddDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Add New Item"),
            content: SingleChildScrollView(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.warning),
                  title: Text("Stock Alert"),
                  onTap: () {
                    Navigator.pop(context);
                    _showStockAlertDialog();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.content_cut),
                  title: Text("Embroidery Order"),
                  onTap: () {
                    Navigator.pop(context);
                    _showEmbroideryDialog();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.note),
                  title: Text("Custom Reminder"),
                  onTap: () {
                    Navigator.pop(context);
                    _showCustomReminderDialog();
                  },
                )
              ],
            )),
          );
        });
  }

  void _showStockAlertDialog() {
    final _formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    int quantity = 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New Stock Alert'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Item Name'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => title = value ?? '',
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Current Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (int.tryParse(value) == null)
                        return 'Must be a number';
                      return null;
                    },
                    onSaved: (value) => quantity = int.parse(value ?? '0'),
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Additional Notes'),
                    maxLines: 2,
                    onSaved: (value) => description = value ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();

                  await _reminderManager.addReminder(
                    type: ReminderType.stockAlert,
                    title: title,
                    description: 'Current Quantity: $quantity\n$description',
                    dueDate: null,
                  );

                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEmbroideryDialog() {
    final _formKey = GlobalKey<FormState>();
    String uniformItem = '';
    String shopName = '';
    String color = '';
    String size = '';
    int quantity = 0;
    String? notes;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New Embroidery Order'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Uniform Item'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => uniformItem = value ?? '',
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Shop Name'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => shopName = value ?? '',
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Color'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => color = value ?? '',
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Size'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => size = value ?? '',
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (int.tryParse(value) == null)
                        return 'Must be a number';
                      return null;
                    },
                    onSaved: (value) => quantity = int.parse(value ?? '0'),
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Notes (Optional)'),
                    maxLines: 2,
                    onSaved: (value) => notes = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();

                  await _reminderManager.addEmbroideryItem(
                    uniformItem: uniformItem,
                    color: color,
                    size: size,
                    quantity: quantity,
                    shopName: shopName,
                    notes: notes,
                  );

                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showCustomReminderDialog() {
    final _formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('New Custom Reminder'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Title'),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => title = value ?? '',
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                    onSaved: (value) => description = value ?? '',
                  ),
                  ListTile(
                    title: Text('Due Date (Optional)'),
                    subtitle: Text(dueDate == null
                        ? 'Not set'
                        : DateFormat('yyyy-MM-dd').format(dueDate!)),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (selectedDate != null) {
                        setState(() => dueDate = selectedDate);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();

                  await _reminderManager.addReminder(
                    type: ReminderType.customReminder,
                    title: title,
                    description: description,
                    dueDate: dueDate,
                  );

                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
