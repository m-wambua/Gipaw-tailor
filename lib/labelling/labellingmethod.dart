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

    var urlData =
        json.containsKey('imageUrls') ? json['imageUrls'] : json['imageUrl'];

    return LabelOrder(
      orderNumber: json['orderNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      customerName: json['customerName'],
      customerPhoneNumber: json['customerPhoneNumber'],
      customerEmail: json['customerEmail'],
      labelType: json['labelType'],
      imageUrls: List<String>.from(json['imageUrls']),
      notes: json['notes'],
      item: json['item'],
      label: json['label'],
      totalAmount: json['totalAmount'],
      payments: (json['payments'] as List)
          .map((e) => LabelPayment.fromJson(e))
          .toList(),
      status: LabelOrderStatus.values
          .firstWhere((element) => element.toString() == json['status']),
      fufillmentDate: json['fufillmentDate'] != null
          ? DateTime.parse(json['fufillmentDate'])
          : null,
      createdBy: json['createdBy'],
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
    return LabelPayment(
      paymentId: json['paymentId'],
      amount: json['amount'],
      status: LabellingPaymentStatus.values
          .firstWhere((element) => element.toString() == json['status']),
      paymentDate: DateTime.parse(json['paymentDate']),
      paymentType: json['paymentType'],
      receiptNumber: json['receiptNumber'],
      recordedBy: json['recordedBy'],
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
      Map orderJson = order.toJson();
      int existingIndex = orders.indexWhere((orderstr) {
        Map existing = jsonDecode(orderstr);
        return existing['orderNumber'] == order.orderNumber;
      });
      if (existingIndex >= 0) {
        orders[existingIndex] = jsonEncode(orderJson);
      } else {
        orders.add(jsonEncode(orderJson));
      }
      final result = await prefs.setStringList(_storageKey, orders);
      return result;
    } catch (e) {
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
    if (orders.isEmpty) {
      return [];
    }
    try {
      List<LabelOrder> parsedOrders = orders.map((orderString) {
        Map orderMap = jsonDecode(orderString);
        return LabelOrder.fromJson(orderMap.cast<String, dynamic>());
      }).toList();
      return parsedOrders;
    } catch (e) {
      rethrow;
    }
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
    return orders
        .where((order) => !order.isFullyPaid)
        .map((order) {
          final balance = order.remainingBalance;
          return PendingBalanceLabelling(order.customerName, balance);
        })
        .toList();
  }
}

class PendingBalanceLabelling{
  final String customerName;
  final double balance;
  PendingBalanceLabelling(this.customerName, this.balance);


}

double calculateTotalSales(List<LabelOrder> orders) {
  return orders.fold(0.0,
      (sum, item) => sum + double.parse((item.totalAmount).toStringAsFixed(2)));
}

Map<String,double> getPaymentBreakdown(List<LabelOrder> items){
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

List<PendingBalanceLabelling>  getPendingBalances(List<LabelOrder> items){
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
