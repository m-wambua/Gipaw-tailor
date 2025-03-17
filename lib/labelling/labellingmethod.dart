import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

enum LabelOrderStatus {
  pending,
  partial,
  paid,
  fulfilled,
  cancelled,
}

enum LabellingPaymentStatus { deposit, partial, finalpayment }

class LabelOrder {
  final String orderNumber;
  final DateTime createdAt;
  final String customerName;
  final String customerPhoneNumber;
  String? customerEmail;
  final String labelType;
  final List<String?> imageUrls;
  final String notes;
  final String item;
  final String label;
  final double totalAmount;
  final List<LabelPayment> payments;
  LabelOrderStatus status;
  DateTime? fufillmentDate;
  String createdBy;

  LabelOrder({
    required this.orderNumber,
    required this.createdAt,
    required this.customerName,
    required this.customerPhoneNumber,
    this.customerEmail,
    required this.labelType,
    this.imageUrls = const [],
    required this.notes,
    required this.item,
    required this.label,
    required this.totalAmount,
    required this.payments,
    this.status = LabelOrderStatus.pending,
    this.fufillmentDate,
    required this.createdBy,
  });

  double get totalPaid => payments.fold(
      0, (previousValue, element) => previousValue + element.amount);
  bool get isFullyPaid => remainingBalance <= 0;

  double get remainingBalance => totalAmount - totalPaid;

  Map<String, dynamic> toJson() => {
        'orderNumber': orderNumber,
        'createdAt': createdAt.toIso8601String(),
        'customerName': customerName,
        'customerPhoneNumber': customerPhoneNumber,
        'customerEmail': customerEmail,
        'labelType': labelType,
        'imageUrls': imageUrls,
        'notes': notes,
        'item': item,
        'label': label,
        'totalAmount': totalAmount,
        'payments': payments.map((e) => e.toJson()).toList(),
        'status': status.toString().split('.').last,
        'fufillmentDate': fufillmentDate?.toIso8601String(),
        'createdBy': createdBy,
      };
  factory LabelOrder.fromJson(Map<String, dynamic> json) {
    List<String?> parseImageUrls(dynamic imageUrls) {
      if (imageUrls == null) return [];
      if (imageUrls is String) return [imageUrls];

      if (imageUrls is List) {
        return imageUrls.map((e) => e as String?).toList();
      }
      return [];
    }

    // Helper function to safely parse the status enum
    LabelOrderStatus parseStatus(dynamic statusValue) {
      if (statusValue == null) return LabelOrderStatus.pending;

      // Convert to string and handle different formats
      String statusStr = statusValue.toString();

      // Try to match with the enum name directly (e.g., "pending")
      try {
        return LabelOrderStatus.values.firstWhere(
            (element) => element.toString().split('.').last == statusStr,
            orElse: () =>
                LabelOrderStatus.pending // Important: Provide a default value
            );
      } catch (e) {
        print("Error parsing status: $e");
        return LabelOrderStatus.pending;
      }
    }

    // Similar helper for payment status
    LabellingPaymentStatus parsePaymentStatus(dynamic statusValue) {
      if (statusValue == null) return LabellingPaymentStatus.deposit;

      String statusStr = statusValue.toString();

      try {
        return LabellingPaymentStatus.values.firstWhere(
            (element) => element.toString().split('.').last == statusStr,
            orElse: () => LabellingPaymentStatus.deposit);
      } catch (e) {
        print("Error parsing payment status: $e");
        return LabellingPaymentStatus.deposit;
      }
    }

    var urlData =
        json.containsKey('imageUrls') ? json['imageUrls'] : json['imageUrl'];
    List<String?> processedImageUrls = parseImageUrls(urlData);

    // Safe parsing of payments
    List<LabelPayment> payments = [];
    if (json['payments'] != null && json['payments'] is List) {
      payments = (json['payments'] as List).map((paymentJson) {
        try {
          return LabelPayment.fromJson(paymentJson);
        } catch (e) {
          print("Error parsing payment: $e");
          // Return a default payment to avoid crashing
          return LabelPayment(
            paymentId: 'error_${DateTime.now().millisecondsSinceEpoch}',
            amount: 0.0,
            status: LabellingPaymentStatus.deposit,
            paymentDate: DateTime.now(),
            paymentType: 'unknown',
            recordedBy: 'system',
          );
        }
      }).toList();
    }

    return LabelOrder(
      orderNumber: json['orderNumber'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      customerName: json['customerName'] ?? '',
      customerPhoneNumber: json['customerPhoneNumber'] ?? '',
      customerEmail: json['customerEmail'],
      labelType: json['labelType'] ?? '',
      imageUrls: processedImageUrls,
      notes: json['notes'] ?? '',
      item: json['item'] ?? '',
      label: json['label'] ?? '',
      totalAmount:
          (json['totalAmount'] is num) ? json['totalAmount'].toDouble() : 0.0,
      payments: payments,
      status: parseStatus(json['status']),
      fufillmentDate: json['fufillmentDate'] != null
          ? DateTime.parse(json['fufillmentDate'])
          : null,
      createdBy: json['createdBy'] ?? '',
    );
  }
}

class LabelPayment {
  final String paymentId;

  final double amount;
  final LabellingPaymentStatus status;
  final DateTime paymentDate;
  final String paymentType;
  final String? receiptNumber;
  final String recordedBy;

  LabelPayment({
    required this.paymentId,
    required this.amount,
    required this.status,
    required this.paymentDate,
    required this.paymentType,
    this.receiptNumber,
    required this.recordedBy,
  });

  Map<String, dynamic> toJson() => {
        'paymentId': paymentId,
        'amount': amount,
        'status': status.toString().split('.').last,
        'paymentDate': paymentDate.toIso8601String(),
        'paymentType': paymentType,
        'receiptNumber': receiptNumber,
        'recordedBy': recordedBy,
      };

  factory LabelPayment.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse the payment status enum
    LabellingPaymentStatus parsePaymentStatus(dynamic statusValue) {
      if (statusValue == null) return LabellingPaymentStatus.deposit;

      String statusStr = statusValue.toString();

      try {
        return LabellingPaymentStatus.values.firstWhere(
            (element) => element.toString().split('.').last == statusStr,
            orElse: () => LabellingPaymentStatus.deposit);
      } catch (e) {
        print("Error parsing payment status: $e");
        return LabellingPaymentStatus.deposit;
      }
    }

    return LabelPayment(
      paymentId: json['paymentId'] ??
          'unknown-${DateTime.now().millisecondsSinceEpoch}',
      amount: json['amount'] is num ? json['amount'].toDouble() : 0.0,
      status: parsePaymentStatus(json['status']),
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : DateTime.now(),
      paymentType: json['paymentType'] ?? 'unknown',
      receiptNumber: json['receiptNumber'],
      recordedBy: json['recordedBy'] ?? 'system',
    );
  }
}

class LabelPaymentEntry {
  String deposit;
  String balance;
  String paymentType;
  DateTime paymentDate;
  LabelPaymentEntry({
    required this.deposit,
    required this.balance,
    required this.paymentType,
    required this.paymentDate,
  });
  Map<String, dynamic> toJson() => {
        'deposit': deposit,
        'balance': balance,
        'paymentType': paymentType,
        'paymentDate': paymentDate.toIso8601String(),
      };
  factory LabelPaymentEntry.fromJson(Map<String, dynamic> json) {
    return LabelPaymentEntry(
      deposit: json['deposit'],
      balance: json['balance'],
      paymentType: json['paymentType'],
      paymentDate: DateTime.parse(json['paymentDate']),
    );
  }
  static String calculateBalance(String charges, String deposit) {
    double chargesAmount = double.parse(charges);
    double depositAmount = double.parse(deposit);
    double balance = chargesAmount - depositAmount;
    return balance.toStringAsFixed(2);
  }
}

class LabelService {
  static const String _storageKey = "label_orders";
  String generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100).toString().padLeft(2, '0');
    return 'LBON$timestamp$random';
  }

  String generatePaymentId(String orderNumber) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(100).toString().padLeft(2, '0');
    return 'LBPT$timestamp$random';
  }

  Future<bool> saveLabelOrder(LabelOrder order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> orders = prefs.getStringList(_storageKey) ?? [];

      // Proper typing
      Map<String, dynamic> orderJson = order.toJson();

      // For debugging
      print("Saving order: ${order.orderNumber}");
      print("JSON being saved: ${jsonEncode(orderJson)}");

      int existingIndex = orders.indexWhere((orderstr) {
        try {
          Map<String, dynamic> existing =
              jsonDecode(orderstr) as Map<String, dynamic>;
          return existing['orderNumber'] == order.orderNumber;
        } catch (e) {
          print("Error parsing existing order: $e");
          return false;
        }
      });

      if (existingIndex >= 0) {
        orders[existingIndex] = jsonEncode(orderJson);
        print("Updated existing order at index $existingIndex");
      } else {
        orders.add(jsonEncode(orderJson));
        print("Added new order");
      }

      final result = await prefs.setStringList(_storageKey, orders);
      print("Save result: $result");
      return result;
    } catch (e) {
      print("Error saving label order: $e");
      return false;
    }
  }

  Future<LabelOrder?> getLabelOrder(String orderNumber) async {
    final orders = await getAllLabelOrders();
    try {
      return orders.firstWhere((element) => element.orderNumber == orderNumber);
    } catch (e) {
      return null;
    }
  }

  Future<List<LabelOrder>> getAllLabelOrders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> orders = prefs.getStringList(_storageKey) ?? [];

    print("Found ${orders.length} saved orders");

    if (orders.isEmpty) {
      return [];
    }

    List<LabelOrder> parsedOrders = [];

    for (int i = 0; i < orders.length; i++) {
      try {
        String orderString = orders[i];
        print("Parsing order $i...");

        // Try to parse the JSON string
        Map<String, dynamic> orderMap =
            jsonDecode(orderString) as Map<String, dynamic>;

        // Check for critical fields
        if (!orderMap.containsKey('orderNumber')) {
          print("Warning: Order $i is missing orderNumber");
          continue;
        }

        // Try to create a LabelOrder object
        LabelOrder order = LabelOrder.fromJson(orderMap);
        parsedOrders.add(order);

        print("Successfully parsed order ${order.orderNumber}");
      } catch (e, stackTrace) {
        // Print both the error and stack trace for better debugging
        print("Error parsing order $i: $e");
        print("Stack trace: $stackTrace");
        // Continue to next order instead of failing
      }
    }

    print(
        "Successfully parsed ${parsedOrders.length} out of ${orders.length} orders");
    return parsedOrders;
  }

  double calculateTotalSales(List<LabelOrder> orders) {
    return orders.fold(
        0, (previousValue, element) => previousValue + element.totalAmount);
  }

  Map<String, double> getPaymentMethodBreakdown(List<LabelOrder> orders) {
    final breakdown = <String, double>{};
    for (var order in orders) {
      for (var payment in order.payments) {
        breakdown.update(payment.paymentType, (value) => value + payment.amount,
            ifAbsent: () => payment.amount);
      }
    }
    return breakdown;
  }

  List<PendingBalanceLabelling> getPendingBalances(List<LabelOrder> orders) {
    return orders.where((order) => !order.isFullyPaid).map((order) {
      final balance = order.remainingBalance;
      return PendingBalanceLabelling(order.customerName, balance);
    }).toList();
  }
}

class PendingBalanceLabelling {
  final String customerName;
  final double balance;
  PendingBalanceLabelling(this.customerName, this.balance);
}

double calculateTotalSales(List<LabelOrder> orders) {
  return orders.fold(0.0,
      (sum, item) => sum + double.parse((item.totalAmount).toStringAsFixed(2)));
}

Map<String, double> getPaymentBreakdown(List<LabelOrder> items) {
  final breakdown = <String, double>{};

  for (var item in items) {
    for (var payment in item.payments) {
      breakdown.update(
        payment.paymentType,
        (value) => value + double.parse((payment.amount).toStringAsFixed(2)),
        ifAbsent: () => double.parse((payment.amount).toStringAsFixed(2)),
      );
    }
  }

  return breakdown;
}

List<PendingBalanceLabelling> getPendingBalances(List<LabelOrder> items) {
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
    return PendingBalanceLabelling(item.customerName, balance);
  }).toList();
}
