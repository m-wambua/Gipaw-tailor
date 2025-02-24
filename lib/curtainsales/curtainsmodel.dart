import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gipaw_tailor/clothesentrymodel/newandrepare.dart';
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
  final String? imageUrl;
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
    this.imageUrl,
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
        'imageUrl': imageUrl,
        'notes': notes,
        'part': part,
        'measurement': measurement,
        'totalAmount': totalAmount,
        'status': status.name, // Using .name to get the enum value as a string
        'fulfillmentDate': fulfillmentDate?.toIso8601String(),
        'createdBy': createdBy,
        'payments': payments.map((p) => p.toJson()).toList(),
      };
  factory CurtainOrder.fromJson(Map<String, dynamic> json) => CurtainOrder(
        orderNumber: json['orderNumber'],
        createdAt: DateTime.parse(json['createdAt']),
        customerName: json['customerName'],
        phoneNumber: json['phoneNumber'],
        materialOwner: json['materialOwner'],
        curtainType: json['curtainType'],
        imageUrl: json['imageUrl'],
        notes: json['notes'],
        part: json['part'],
        measurement: json['measurement'],
        totalAmount: (json['totalAmount'] as num).toDouble(),
        status: CurtainOrderStatus.values
            .byName(json['status']), // This is the key fix
        fulfillmentDate: json['fulfillmentDate'] != null
            ? DateTime.parse(json['fulfillmentDate'])
            : null,
        createdBy: json['createdBy'],
        payments: (json['payments'] as List)
            .map((p) => CurtainPayment.fromJson(p))
            .toList(),
      );
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

class CurtainItem {
  String name;
  String phoneNumber;
  String materialOwner;
  String curtainType;

  String? imageUrl;
  String notes;
  String part;
  String measurement;
  String charges;
  DateTime orderDate;
  List<CurtainpaymentEntry> curtainPaymentEntries;
  DateTime? pickUpDate;

  CurtainItem({
    required this.name,
    required this.phoneNumber,
    required this.materialOwner,
    required this.curtainType,
    this.imageUrl,
    required this.notes,
    required this.part,
    required this.measurement,
    required this.charges,
    required this.orderDate,
    this.curtainPaymentEntries = const [],
    this.pickUpDate,
  });
  Map<String, dynamic> toJson() => {
        'name': name,
        'phoneNumber': phoneNumber,
        'materialOwner': materialOwner,
        'notes': notes,
        'curtainType': curtainType,
        'imageUrl': imageUrl,
        'part': part,
        'measurement': measurement,
        'charges': charges,
        'orderDate': orderDate.toIso8601String(),
        'curtainPaymentEntries':
            curtainPaymentEntries.map((e) => e.toJson()).toList(),
        'pickUpDate': pickUpDate?.toIso8601String()
      };
  factory CurtainItem.fromJson(Map<String, dynamic> json) => CurtainItem(
        name: json['name'],
        phoneNumber: json['phoneNumber'],
        materialOwner: json['materialOwner'],
        notes: json['notes'],
        part: json['part'],
        measurement: json['measurement'],
        curtainType: json['curtainType'],
        imageUrl: json['imageUrl'],
        charges: json['charges'],
        orderDate: DateTime.parse(json['orderDate']),
        curtainPaymentEntries: (json['curtainPaymentEntries'] as List)
            .map((entry) => CurtainpaymentEntry.fromJson(entry))
            .toList(),
        pickUpDate: json['pickUpDate'] != null
            ? DateTime.parse(json['pickUpDate'])
            : null,
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

class CurtainManager {
  static Future<void> saveCurtainItem(
    List<CurtainItem> curtainItems,
  ) async {
    try {
      const baseDir = 'lib/curtainsales/curtainsstorage';
      final curtainDirPath = path.join(baseDir);
      final curtainDir = Directory(curtainDirPath);

      if (!await curtainDir.exists()) {
        await curtainDir.create(recursive: true);
        if (await curtainDir.exists()) {
          print('Curtain directory created');
        } else {
          print("Failed to create curtain directory");
          return;
        }
      }

      final filePath = path.join(curtainDirPath, 'curtain.json');
      final file = File(filePath);
      final jsonList = curtainItems.map((ci) => ci.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
      print("Curtain item saved");
    } catch (e) {
      print('Error saving curtain items: $e');
      rethrow;
    }
  }

  static Future<List<CurtainItem>> loadCurtainItems() async {
    try {
      const baseDir = 'lib/curtainsales/curtainsstorage';
      final curtainDirPath = path.join(baseDir);
      final filePath = path.join(curtainDirPath, "curtain.json");
      final file = File(filePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = json.decode(contents);
        final List<CurtainItem> curtainItems = jsonList
            .map((jsonItems) => CurtainItem.fromJson(jsonItems))
            .toList();
        return curtainItems;
      } else {
        print('Curtain directory does not exist');
        return [];
      }
    } catch (e) {
      print('Error loading curtain items: $e');
      rethrow;
    }
  }
}

class PendingBalance {
  final String customerName;
  final double amount;

  PendingBalance(this.customerName, this.amount);
}

double calculateTotalSales(List<CurtainItem> items) {
  return items.fold(0.0, (sum, item) => sum + double.parse(item.charges));
}

Map<String, double> getPaymentTypeBreakdown(List<CurtainItem> items) {
  final breakdown = <String, double>{};

  for (var item in items) {
    for (var payment in item.curtainPaymentEntries) {
      breakdown.update(
        payment.paymentMethod,
        (value) => value + double.parse(payment.deposit),
        ifAbsent: () => double.parse(payment.deposit),
      );
    }
  }

  return breakdown;
}

List<PendingBalance> getPendingBalances(List<CurtainItem> items) {
  return items.where((item) {
    final totalPaid = item.curtainPaymentEntries.fold(
      0.0,
      (sum, payment) => sum + double.parse(payment.deposit),
    );
    return totalPaid < double.parse(item.charges);
  }).map((item) {
    final totalPaid = item.curtainPaymentEntries.fold(
      0.0,
      (sum, payment) => sum + double.parse(payment.deposit),
    );
    final balance = double.parse(item.charges) - totalPaid;
    return PendingBalance(item.name, balance);
  }).toList();
}
