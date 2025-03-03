import 'dart:convert';
import 'dart:math';

import 'package:gipaw_tailor/curtainsales/curtainsmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ClothesOrderStatus {
  pending,
  partial,
  paid,
  fuflilled,
  cancelled,
}

enum ClothingPaymentStatus { deposit, partial, finalpayment }

ClothingPaymentStatus _determinePaymentStatus({
  required double totalAmount,
  required double currentlyPaid,
  required double newPaymentAmount,
}) {
  final double totalAfterPayment = currentlyPaid + newPaymentAmount;
  if (currentlyPaid == 0) {
    return ClothingPaymentStatus.deposit;
  } else if (totalAfterPayment >= totalAmount) {
    return ClothingPaymentStatus.finalpayment;
  } else {
    return ClothingPaymentStatus.partial;
  }
}

ClothesOrderStatus _determineOrderStatus(
    {required double totalAmount, required double totalPaid}) {
  if (totalPaid >= totalAmount) {
    return ClothesOrderStatus.paid;
  } else if (totalPaid > 0) {
    return ClothesOrderStatus.partial;
  } else {
    return ClothesOrderStatus.pending;
  }
}

class ClothingOrder {
  final String orderName;
  final DateTime createdAt;
  final String customerName;
  final String phoneNumber;
  final String? email;
  final String materialOwner;

  final String? imageUrl;
  final String notes;
  final String part;
  final String measurement;
  final double totalAmount;
  final List<ClothingPayment> payments;
  ClothesOrderStatus status;
  DateTime? fulfillmentDate;
  String createdBy;

  ClothingOrder({
    required this.orderName,
    required this.createdAt,
    required this.customerName,
    required this.phoneNumber,
    this.email,
    required this.materialOwner,
    required this.imageUrl,
    required this.notes,
    required this.part,
    required this.measurement,
    required this.totalAmount,
    required this.payments,
    this.status = ClothesOrderStatus.pending,
    required this.fulfillmentDate,
    required this.createdBy,
  });
  double get totalPaid =>
      payments.fold(0.0, (sum, payments) => sum + payments.amount);

  double get remainingBalance => totalAmount - totalPaid;
  bool get isFullyPaid => remainingBalance <= 0;

  Map<String, dynamic> toJson() => {
        'orderName': orderName,
        'createdAt': createdAt.toIso8601String(),
        'customerName': customerName,
        'phoneNumber': phoneNumber,
        'email': email,
        'materialOwner': materialOwner,
        'imageUrl': imageUrl,
        'notes': notes,
        'part': part,
        'measurement': measurement,
        'totalAmount': totalAmount,
        'payments': payments.map((payment) => payment.toJson()).toList(),
        'status': status.name,
        'fulfillmentDate': fulfillmentDate?.toIso8601String(),
        'createdBy': createdBy,
      };

  factory ClothingOrder.fromJson(Map<String, dynamic> json) => ClothingOrder(
        orderName: json['orderName'],
        createdAt: DateTime.parse(json['createdAt']),
        customerName: json['customerName'],
        phoneNumber: json['phoneNumber'],
        email: json['email'],
        materialOwner: json['materialOwner'],
        notes: json['notes'],
        part: json['part'],
        measurement: json['measurement'],
        totalAmount: (json['totalAmount'] as num).toDouble(),
        payments: (json['payments'] as List)
            .map((p) => ClothingPayment.fromJson(p))
            .toList(),
        createdBy: json['createdBy'],
        status: ClothesOrderStatus.values.byName(json['status']),
        fulfillmentDate: json['fulfillmentDate'] != null
            ? DateTime.parse(json['fulfillmentDate'])
            : null,
        imageUrl: json['imageUrl'],
      );
}

class ClothingPayment {
  final String paymentId;
  final DateTime timestamp;
  final double amount;
  final String method;
  final ClothingPaymentStatus status;
  final String? receiptNumber;
  final String recorderdBy;

  ClothingPayment({
    required this.paymentId,
    required this.timestamp,
    required this.amount,
    required this.method,
    required this.status,
    required this.receiptNumber,
    required this.recorderdBy,
  });

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'timestamp': timestamp.toIso8601String(),
        'amount': amount,
        'method': method,
        'status': status.toString(),
        'receiptNumber': receiptNumber,
        'recorderdBy': recorderdBy,
      };
  factory ClothingPayment.fromJson(Map<String, dynamic> json) =>
      ClothingPayment(
        paymentId: json['paymentId'],
        timestamp: DateTime.parse(json['timestamp']),
        amount: (json['amount'] as num).toDouble(),
        method: json['method'],
        status: ClothingPaymentStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
          orElse: () => ClothingPaymentStatus.partial,
        ),
        receiptNumber: json['receiptNumber'],
        recorderdBy: json['recorderdBy'],
      );
}

class ClothingService {
  static const String _storageKey = 'clothing_orders';
  String generateOrderNumber() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(100).toString().padLeft(2, '0');
    return 'CLOTH-$timestamp-$random';
  }

  String generatePaymentId(String OrderNumber) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(100).toString().padLeft(2, '0');
    return 'PAY-$timestamp-$random';
  }

  Future<bool> saveClothingOrder(ClothingOrder order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> orders = prefs.getStringList(_storageKey) ?? [];
      Map orderJson = order.toJson();
      int existingIndex = orders.indexWhere((orderStr) {
        Map existing = jsonDecode(orderStr);
        return existing['orderName'] == order.orderName;
      });
      if (existingIndex >= 0) {
        orders[existingIndex] = jsonEncode(orderJson);
      } else {
        orders.add(jsonEncode(orderJson));
      }
      final result = await prefs.setStringList(_storageKey, orders);
      print(
        'Order saved successfully: $result,total orders: ${orders.length}',
      );
      return result;
    } catch (e) {
      print('Error saving clothing order: $e');
      return false;
    }
  }

  Future<ClothingOrder?> getClothingOrder(String orderName) async {
    final orders = await getAllClothingOrders();
    try {
      return orders.firstWhere((order) => order.orderName == orderName);
    } catch (e) {
      print('Error getting clothing order: $e');
      return null;
    }
  }

  Future<List<ClothingOrder>> getAllClothingOrders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> orders = prefs.getStringList(_storageKey) ?? [];
    print('Row orders from SharedPreferences:$orders');
    if (orders.isEmpty) {
      print('No orders found');
      return [];
    }
    try {
      List<ClothingOrder> parseOrders = orders.map((orderString) {
        Map orderJson = jsonDecode(orderString);
        return ClothingOrder.fromJson(orderJson.cast<String, dynamic>());
      }).toList();
      return parseOrders;
    } catch (e) {
      rethrow;
    }
  }

  double calculateTotalSales(List<ClothingOrder> orders) {
    return orders.fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  Map<String, double> getPaymentMethodsBreakDown(List<ClothingOrder> orders) {
    final breakdown = <String, double>{};
    for (var order in orders) {
      for (var payment in order.payments) {
        breakdown.update(
          payment.method,
          (value) => value + payment.amount,
          ifAbsent: () => payment.amount,
        );
      }
    }
    return breakdown;
  }

  List<PendingBalance> getPendingBalances(List<ClothingOrder> orders) {
    return orders.where((order) {
      return !order.isFullyPaid;
    }).map((order) {
      final balance = order.remainingBalance;
      return PendingBalance(order.customerName, balance);
    }).toList();
  }
}

class PaymentEntry {
  String deposit;
  String balance;
  DateTime paymentDate;
  String paymentType;

  PaymentEntry({
    required this.deposit,
    required this.balance,
    required this.paymentDate,
    required this.paymentType,
  });

  Map<String, dynamic> toJson() => {
        'deposit': deposit,
        'balance': balance,
        'paymentDate': paymentDate.toIso8601String(),
        'paymentType': paymentType
      };
  factory PaymentEntry.fromJson(Map<String, dynamic> json) => PaymentEntry(
      deposit: json['deposit'],
      balance: json['balance'],
      paymentDate: DateTime.parse(json['paymentDate']),
      paymentType: json['paymentType']);

  static String calculateBalance(String charges, String deposit) {
    double chargesAmount = double.parse(charges);
    double depositAmount = double.parse(deposit);
    double remainingBalance = chargesAmount - depositAmount;
    return remainingBalance.toStringAsFixed(2);
  }
}

class ClothingItemIdentifier {
  /// Generates a unique identifier for a clothing item by combining name and phone number
  ///
  /// [name] The name of the customer
  /// [phoneNumber] The phone number of the customer
  ///
  /// Returns a sanitized string that can be used as a filename or identifier
  static String generateIdentifier(String name, String phoneNumber) {
    // Remove any non-alphanumeric characters
    String sanitizedName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    String sanitizedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Combine and convert to lowercase to ensure consistency
    String identifier = '${sanitizedName.toLowerCase()}_$sanitizedPhone';

    return identifier;
  }
}
