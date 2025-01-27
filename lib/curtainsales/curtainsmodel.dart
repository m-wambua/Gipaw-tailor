import 'dart:convert';
import 'dart:io';

import 'package:gipaw_tailor/clothesentrymodel/newandrepare.dart';
import 'package:path/path.dart' as path;

class CurtainItem {
  String name;
  String phoneNumber;
  String materialOwner;
  String measurements;
  String part;
  String measurement;
  String charges;
  List<CurtainpaymentEntry> curtainPaymentEntries;
  DateTime? pickUpDate;

  CurtainItem({
    required this.name,
    required this.phoneNumber,
    required this.materialOwner,
    required this.measurements,
    required this.part,
    required this.measurement,
    required this.charges,
    this.curtainPaymentEntries = const [],
    this.pickUpDate,
  });
  Map<String, dynamic> toJson() => {
        'name': name,
        'phoneNumber': phoneNumber,
        'materialOwner': materialOwner,
        'measurements': measurements,
        'part': part,
        'measurement': measurement,
        'charges': charges,
        'curtainPaymentEntries':
            curtainPaymentEntries.map((e) => e.toJson()).toList(),
        'pickUpDate': pickUpDate?.toIso8601String()
      };
  factory CurtainItem.fromJson(Map<String, dynamic> json) => CurtainItem(
        name: json['name'],
        phoneNumber: json['phoneNumber'],
        materialOwner: json['materialOwner'],
        measurements: json['measurements'],
        part: json['part'],
        measurement: json['measurement'],
        charges: json['charges'],
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
          final curtainFile = File(path.join(curtainDirPath, 'curtain.json'));
          await curtainFile.writeAsString(
              curtainItems.map((e) => e.toJson()).toList().toString());
        }
      } else {
        final curtainFile = File(path.join(curtainDirPath, 'curtain.json'));
        await curtainFile.writeAsString(
            curtainItems.map((e) => e.toJson()).toList().toString());
      }
    } catch (e) {
      print('Error saving curtain items: $e');
      rethrow;
    }
  }

  static Future<List<CurtainItem>> loadCurtainItems() async {
    try {
      const baseDir = 'lib/curtainsales/curtainsstorage';
      final curtainDirPath = path.join(baseDir);
      final curtainDir = Directory(curtainDirPath);
      if (await curtainDir.exists()) {
        final curtainFile = File(path.join(curtainDirPath, 'curtain.json'));
        if (await curtainFile.exists()) {
          final curtainJson = await curtainFile.readAsString();
          final curtainList = (json.decode(curtainJson) as List)
              .map((e) => CurtainItem.fromJson(e))
              .toList();
          return curtainList;
        } else {
          print('Curtain file does not exist');
          return [];
        }
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

double calculateTotalSales(List<ClothingItem> items) {
  return items.fold(0.0, (sum, item) => sum + double.parse(item.charges));
}

Map<String, double> getPaymentTypeBreakdown(List<ClothingItem> items) {
  final breakdown = <String, double>{};
  
  for (var item in items) {
    for (var payment in item.paymentEntries) {
      breakdown.update(
        payment.paymentType,
        (value) => value + double.parse(payment.deposit),
        ifAbsent: () => double.parse(payment.deposit),
      );
    }
  }
  
  return breakdown;
}

List<PendingBalance> getPendingBalances(List<ClothingItem> items) {
  return items.where((item) {
    final totalPaid = item.paymentEntries.fold(
      0.0,
      (sum, payment) => sum + double.parse(payment.deposit),
    );
    return totalPaid < double.parse(item.charges);
  }).map((item) {
    final totalPaid = item.paymentEntries.fold(
      0.0,
      (sum, payment) => sum + double.parse(payment.deposit),
    );
    final balance = double.parse(item.charges) - totalPaid;
    return PendingBalance(item.name, balance);
  }).toList();
}
