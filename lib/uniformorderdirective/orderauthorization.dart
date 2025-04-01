import 'package:flutter/material.dart';
import 'package:gipaw_tailor/uniformorderdirective/uniformorder.dart';

class UniformOrder {
  final String id;
  final List<UniformOrderItem> items;
  final String tailorName;
  final DateTime scheduledDate;
  final TimeOfDay scheduledTime;
  final UrgencyLevel urgencyLevel;
  OrderStatus status;
  double? finalPrice;

  List<UniformOrderItem> completedItems = [];
  DateTime? completionDate;

  UniformOrder({
    required this.id,
    required this.items,
    required this.tailorName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.urgencyLevel,
    this.status = OrderStatus.pending,
    this.finalPrice,
    this.completedItems = const [],
    this.completionDate,
  });

  double get completionPerentage {
    if (items.isEmpty) return 0.0;
    int totalOrdered = 0;
    int totalCompleted = 0;

    for (var item in items) {
      totalOrdered += item.quantity;
    }

    for (var item in completedItems) {
      totalCompleted += item.quantity;
    }
    return (totalCompleted / totalOrdered) * 100;
  }

  int get totalOrderQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  int get totalCompletedQuantity {
    return completedItems.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get isPartiallyCompleted {
    return completedItems.isNotEmpty &&
        totalCompletedQuantity < totalOrderQuantity;
  }

  bool get isfullyCompleted {
    return completedItems.isNotEmpty &&
        totalCompletedQuantity == totalOrderQuantity;
  }

  void markAsCompleted(List<UniformOrderItem> completed,
      {bool isfullyCompleted = false}) {
    this.completedItems = completed;
    this.completionDate = DateTime.now();

    if (isfullyCompleted || isfullyCompleted) {
      this.status = OrderStatus.completedPendingApproval;
    } else if (isfullyCompleted) {
      this.status = OrderStatus.completedPendingApproval;
    } else {
      this.status = OrderStatus.partiallyCompleted;
    }
  }

  void approveOrder(double price) {
    this.finalPrice = price;
    this.status = OrderStatus.approvedAndVerified;
  }
}

class UniformOrderItem {
  final String uniformName;
  final String size;
  final String color;
  final int quantity;

  UniformOrderItem({
    required this.uniformName,
    required this.size,
    required this.color,
    required this.quantity,
  });

  factory UniformOrderItem.fromMap(Map<String, dynamic> map) {
    return UniformOrderItem(
      uniformName: map['selectedUniformItem'] ?? 'Unknown Item',
      size: map['selectedSize'] ?? 'N/A',
      color: map['selectedColor'] ?? 'N/A',
      quantity: int.tryParse(map['numberController'].text) ?? 0,
    );
  }
}

enum OrderStatus {
  pending,
  partiallyCompleted,
  completedPendingApproval,
  approvedAndVerified,
}

class OrdersProvider with ChangeNotifier {
  List<UniformOrder> _orders = [];
  List<UniformOrder> get orders => _orders;

  List<UniformOrder> get pendingOrders => _orders
      .where((order) =>
          order.status == OrderStatus.pending ||
          order.status == OrderStatus.partiallyCompleted)
      .toList();

  List<UniformOrder> get completedPendingApprovalOrders => _orders
      .where((order) => order.status == OrderStatus.completedPendingApproval)
      .toList();

  List<UniformOrder> get approvedAndVerifiedOrders => _orders
      .where((order) => order.status == OrderStatus.approvedAndVerified)
      .toList();

  void addOrder(UniformOrder order) {
    _orders.add(order);
    notifyListeners();
  }

  void markOrderAsCompleted(
      String orderId, List<UniformOrderItem> completedItems,
      {bool isfullCompleted = false}) {
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      _orders[orderIndex]
          .markAsCompleted(completedItems, isfullyCompleted: isfullCompleted);
      notifyListeners();
    }
  }

  void approvedOrder(String orderId, double price) {
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    if (orderIndex != -1) {
      _orders[orderIndex].approveOrder(price);
      notifyListeners();
    }
  }
}
