import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

enum CurtainOrderStatus {
  pending,
  partial,
  paid,
  fulfilled,
  cancelled,
}

enum CurtainPaymentStatus { deposit, partial, finalpayment }

CurtainPaymentStatus _determinePaymentStatus({
  required double totalAmount,
  required double currentlyPaid,
  required double newPaymentAmount,
}) {
  final double totalAfterPayment = currentlyPaid + newPaymentAmount;
  if (currentlyPaid == 0) {
    return CurtainPaymentStatus.deposit;
  } else if (totalAfterPayment >= totalAmount) {
    return CurtainPaymentStatus.finalpayment;
  } else {
    return CurtainPaymentStatus.partial;
  }
}

CurtainOrderStatus _determineOrderStatus({
  required double totalAmount,
  required double totalPaid,
}) {
  if (totalPaid >= totalAmount) {
    return CurtainOrderStatus.paid;
  } else if (totalPaid > 0) {
    return CurtainOrderStatus.partial;
  } else {
    return CurtainOrderStatus.pending;
  }
}

class CurtainOrder {
  final String orderNumber;
  final DateTime createdAt;
  final String customerName;
  final String phoneNumber;
  final String materialOwner;
  final String curtainType;
  final List<String?> imageUrls;
  final String notes;
  final String part;
  final String measurement;
  final double totalAmount;
  final List<CurtainPayment> payments;
  CurtainOrderStatus status;
  DateTime? fulfillmentDate;
  String createdBy;

  CurtainOrder({
    required this.orderNumber,
    required this.createdAt,
    required this.customerName,
    required this.phoneNumber,
    required this.materialOwner,
    required this.curtainType,
    this.imageUrls = const [],
    required this.notes,
    required this.part,
    required this.measurement,
    required this.totalAmount,
    required this.payments,
    this.status = CurtainOrderStatus.pending,
    this.fulfillmentDate,
    required this.createdBy,
  });
  double get totalPaid =>
      payments.fold(0.0, (sum, payment) => sum + payment.amount);

  double get remainingBalance => totalAmount - totalPaid;
  bool get isFullyPaid => remainingBalance <= 0;

  Map<String, dynamic> toJson() => {
        'orderNumber': orderNumber,
        'createdAt': createdAt.toIso8601String(),
        'customerName': customerName,
        'phoneNumber': phoneNumber,
        'materialOwner': materialOwner,
        'curtainType': curtainType,
        'imageUrls': imageUrls, // Changed from 'imageUrl' to 'imageUrls'
        'notes': notes,
        'part': part,
        'measurement': measurement,
        'totalAmount': totalAmount,
        'status': status.name,
        'fulfillmentDate': fulfillmentDate?.toIso8601String(),
        'createdBy': createdBy,
        'payments': payments.map((p) => p.toJson()).toList(),
      };
  factory CurtainOrder.fromJson(Map<String, dynamic> json) {
    // Helper function to parse imageUrls with proper type handling
    List<String?> parseImageUrls(dynamic input) {
      if (input == null) return [];

      // If we get a single string
      if (input is String) return [input];

      // If we get a list
      if (input is List) {
        return input.map((item) {
          // Handle each item in the list
          if (item is String) return item;
          return item?.toString(); // Convert other types to string
        }).toList();
      }

      // Fallback
      return [];
    }

    // Try both 'imageUrls' and 'imageUrl' with the parser
    var urlData =
        json.containsKey('imageUrls') ? json['imageUrls'] : json['imageUrl'];

    return CurtainOrder(
      orderNumber: json['orderNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      customerName: json['customerName'],
      phoneNumber: json['phoneNumber'],
      materialOwner: json['materialOwner'],
      curtainType: json['curtainType'],
      imageUrls: parseImageUrls(urlData),
      notes: json['notes'],
      part: json['part'],
      measurement: json['measurement'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: CurtainOrderStatus.values.byName(json['status']),
      fulfillmentDate: json['fulfillmentDate'] != null
          ? DateTime.parse(json['fulfillmentDate'])
          : null,
      createdBy: json['createdBy'],
      payments: (json['payments'] as List)
          .map((p) => CurtainPayment.fromJson(p))
          .toList(),
    );
  }
}

class CurtainPayment {
  final String paymentId;
  final DateTime timestamp;
  final double amount;
  final String method;
  final CurtainPaymentStatus status;
  final String? receiptNumber;
  final String recordedBy;

  CurtainPayment({
    required this.paymentId,
    required this.timestamp,
    required this.amount,
    required this.method,
    required this.status,
    this.receiptNumber,
    required this.recordedBy,
  });

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'timestamp': timestamp.toIso8601String(),
        'amount': amount,
        'method': method,
        'status': status.toString(),
        'receiptNumber': receiptNumber,
        'recordedBy': recordedBy,
      };

  factory CurtainPayment.fromJson(Map<String, dynamic> json) => CurtainPayment(
        paymentId: json['paymentId'],
        timestamp: DateTime.parse(json['timestamp']),
        amount: json['amount'],
        method: json['method'],
        status: CurtainPaymentStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
        ),
        receiptNumber: json['receiptNumber'],
        recordedBy: json['recordedBy'],
      );
}

class CurtainpaymentEntry {
  String deposit;
  String balance;
  DateTime paymentDate;
  String paymentMethod;

  CurtainpaymentEntry({
    required this.deposit,
    required this.balance,
    required this.paymentDate,
    required this.paymentMethod,
  });
  Map<String, dynamic> toJson() => {
        'deposit': deposit,
        'balance': balance,
        'paymentDate': paymentDate.toIso8601String(),
        'paymentMethod': paymentMethod,
      };
  factory CurtainpaymentEntry.fromJson(Map<String, dynamic> json) =>
      CurtainpaymentEntry(
          deposit: json['deposit'],
          balance: json['balance'],
          paymentDate: DateTime.parse(json['paymentDate']),
          paymentMethod: json['paymentMethod']);

  static String calculateBalance(String charges, String deposit) {
    double chargesAmount = double.parse(charges);
    double depositAmount = double.parse(deposit);
    double remainingbalanceAmount = chargesAmount - depositAmount;
    return remainingbalanceAmount.toStringAsFixed(2);
  }
}

class CurtainService {
  static const String _storageKey = 'curtain_orders';

  String generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100).toString().padLeft(2, '0');
    return 'CRT$timestamp$random';
  }

  String generatePaymentsId(String ordrNumber) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100).toString().padLeft(2, '0');
    return 'CPT$timestamp$random';
  }

  Future<bool> saveCurtainOrder(CurtainOrder order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> orders = prefs.getStringList(_storageKey) ?? [];
      Map orderJson = order.toJson();

      int existingIndex = orders.indexWhere((orderStr) {
        Map existing = jsonDecode(orderStr);
        return existing['orderNumber'] == order.orderNumber;
      });

      if (existingIndex >= 0) {
        orders[existingIndex] = jsonEncode(orderJson);
      } else {
        orders.add(jsonEncode(orderJson));
      }

      final result = await prefs.setStringList(_storageKey, orders);
      print('Order saved successfully. Total orders: ${orders.length}');
      return result;
    } catch (e) {
      print('Error saving order: $e');
      return false;
    }
  }

  Future<CurtainOrder?> getCurtainOrder(String orderNumber) async {
    final orders = await getAllCurtainOrders();
    try {
      return orders.firstWhere(
        (order) => order.orderNumber == orderNumber,
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<CurtainOrder>> getAllCurtainOrders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> orders = prefs.getStringList(_storageKey) ?? [];

    // Add debug prints
    print('Raw orders from SharedPreferences: $orders');

    if (orders.isEmpty) {
      print('No orders found in SharedPreferences');
      return [];
    }

    try {
      List<CurtainOrder> parsedOrders = orders.map((orderString) {
        print('Parsing order string: $orderString');
        Map orderJson = jsonDecode(orderString);
        return CurtainOrder.fromJson(orderJson.cast<String, dynamic>());
      }).toList();

      print('Successfully parsed ${parsedOrders.length} orders');
      return parsedOrders;
    } catch (e) {
      print('Error parsing orders: $e');
      rethrow;
    }
  }

  double calculateTotalSales(List<CurtainOrder> orders) {
    return orders.fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  Map<String, double> getPaymentMethodBreakdown(List<CurtainOrder> orders) {
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

  List<PendingBalance> getPendingBalances(List<CurtainOrder> orders) {
    return orders.where((order) => !order.isFullyPaid).map((order) {
      final balance = order.remainingBalance;
      return PendingBalance(order.customerName, balance);
    }).toList();
  }
}

class PendingBalance {
  final String customerName;
  final double amount;

  PendingBalance(this.customerName, this.amount);
}

double calculateTotalSales(List<CurtainOrder> items) {
  return items.fold(0.0,
      (sum, item) => sum + double.parse((item.totalAmount).toStringAsFixed(2)));
}

Map<String, double> getPaymentTypeBreakdown(List<CurtainOrder> items) {
  final breakdown = <String, double>{};

  for (var item in items) {
    for (var payment in item.payments) {
      breakdown.update(
        payment.method,
        (value) => value + double.parse((payment.amount).toStringAsFixed(2)),
        ifAbsent: () => double.parse((payment.amount).toStringAsFixed(2)),
      );
    }
  }

  return breakdown;
}

List<PendingBalance> getPendingBalances(List<CurtainOrder> items) {
  return items.where((item) {
    final totalPaid = item.payments.fold(
      0.0,
      (sum, payment) => sum + double.parse((payment.amount).toStringAsFixed(2)),
    );
    return totalPaid < double.parse((item.totalAmount).toStringAsFixed(2));
  }).map((item) {
    final totalPaid = item.payments.fold(
      0.0,
      (sum, payment) => sum + double.parse((payment.amount).toStringAsFixed(2)),
    );
    final balance =
        double.parse((item.totalAmount).toStringAsFixed(2)) - totalPaid;
    return PendingBalance(item.customerName, balance);
  }).toList();
}
