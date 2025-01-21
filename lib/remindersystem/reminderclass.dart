import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

enum ReminderType {
  stockAlert,
  embroideryOut,
  embroideryReturn,
  customReminder,
}

enum EmbroideryStatus {
  pending,
  inProgress,
  completed,
  returned,
}

class ReminderItem {
  final String id;
  final ReminderType type;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? dueDate;
  bool isResolved;

  ReminderItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    this.dueDate,
    this.isResolved = false,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString(),
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'isResolved': isResolved,
      };

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'],
      type: ReminderType.values.firstWhere((e) => e.toString() == json['type']),
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isResolved: json['isResolved'],
    );
  }
}

class EmbroideryItem {
  final String id;
  final String uniformItem;
  final String color;
  final String size;
  final int quantity;
  final String shopName;
  final DateTime sentDate;
  DateTime? returnDate;
  EmbroideryStatus status;
  String? notes;
  EmbroideryItem({
    required this.id,
    required this.uniformItem,
    required this.color,
    required this.size,
    required this.quantity,
    required this.shopName,
    required this.sentDate,
    this.returnDate,
    this.status = EmbroideryStatus.pending,
    this.notes,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'uniformItem': uniformItem,
        'color': color,
        'size': size,
        'quantity': quantity,
        'shopName': shopName,
        'sentDate': sentDate.toIso8601String(),
        'returnDate': returnDate?.toIso8601String(),
        'status': status.toString(),
        'notes': notes,
      };
  factory EmbroideryItem.fromJson(Map<String, dynamic> json) {
    return EmbroideryItem(
      id: json['id'],
      uniformItem: json['uniformItem'],
      color: json['color'],
      size: json['size'],
      quantity: json['quantity'],
      shopName: json['shopName'],
      sentDate: DateTime.parse(json['sentDate']),
      returnDate: json['returnDate'] != null
          ? DateTime.parse(json['returnDate'])
          : null,
      status: EmbroideryStatus.values
          .firstWhere((e) => e.toString() == json['status']),
      notes: json['notes'],
    );
  }
}

class ReminderManager {
  final String reminderFilePath;
  final String embroideryFilePath;
  List<ReminderItem> reminders = [];
  List<EmbroideryItem> embroideries = [];
  final _uuid = const Uuid();

  ReminderManager({
    required this.reminderFilePath,
    required this.embroideryFilePath,
  }) {
    loadData();
  }

  Future<void> loadData() async {
    await loadReminders();
    await loadEmbroideryItems();
  }

  Future<void> initialize() async {
    await Future.wait([
      loadReminders(),
      loadEmbroideryItems(),
    ]);
  }

  Future<void> loadReminders() async {
    try {
      final file = File(reminderFilePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        reminders = jsonList.map((e) => ReminderItem.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error loading reminders: $e');
      reminders = [];
    }
  }

  Future<void> loadEmbroideryItems() async {
    try {
      final file = File(embroideryFilePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        embroideries = jsonList.map((e) => EmbroideryItem.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error loading embroidery items: $e');
      embroideries = [];
    }
  }

  Future<void> saveReminders() async {
    try {
      final file = File(reminderFilePath);
      final jsonList = reminders.map((item) => item.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving reminders: $e');
    }
  }

  Future<void> saveEmbroideryItems() async {
    try {
      final file = File(embroideryFilePath);
      final jsonList = embroideries.map((item) => item.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving embroidery items: $e');
    }
  }

  Future<void> addReminder({
    required ReminderType type,
    required String title,
    required String description,
    DateTime? dueDate,
  }) async {
    final reminder = ReminderItem(
      id: _uuid.v4(),
      type: type,
      title: title,
      description: description,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );
    reminders.add(reminder);
    await saveReminders();
  }

  Future<void> addEmbroideryItem({
    required String uniformItem,
    required String color,
    required String size,
    required int quantity,
    required String shopName,
    EmbroideryStatus status = EmbroideryStatus.pending,
    String? notes,
  }) async {
    final embroideryItem = EmbroideryItem(
      id: _uuid.v4(),
      uniformItem: uniformItem,
      color: color,
      size: size,
      quantity: quantity,
      shopName: shopName,
      sentDate: DateTime.now(),
      notes: notes,
    );
    embroideries.add(embroideryItem);
    await saveEmbroideryItems();
  }

  Future<void> updateEmbroideryStatus(
      String id, EmbroideryStatus status) async {
    final embroideryItem = embroideries.firstWhere((e) => e.id == id);
    embroideryItem.status = status;
    if (status == EmbroideryStatus.returned) {
      embroideryItem.returnDate = DateTime.now();
    }
    await saveEmbroideryItems();
  }
}
