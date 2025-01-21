import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

class ClothingItem {
  String name;
  String phoneNumber;
  bool materialOwner;
  String measurements;
  String charges;
  List<PaymentEntry> paymentEntries;
  DateTime? pickUpDate;

  ClothingItem({
    required this.name,
    required this.phoneNumber,
    required this.materialOwner,
    required this.measurements,
    required this.charges,
    this.paymentEntries = const [],
    this.pickUpDate,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phoneNumber': phoneNumber,
        'materialOwner': materialOwner,
        'measurements': measurements,
        'charges': charges,
        'paymentEntries': paymentEntries.map((e) => e.toJson()).toList(),
        'pickUpDate': pickUpDate?.toIso8601String()
      };

  factory ClothingItem.fromJson(Map<String, dynamic> json) => ClothingItem(
        name: json['name'],
        phoneNumber: json['phoneNumber'],
        materialOwner: json['materialOwner'],
        measurements: json['measurements'],
        charges: json['charges'],
        paymentEntries: (json['paymentEntries'] as List)
            .map((entry) => PaymentEntry.fromJson(entry))
            .toList(),
        pickUpDate: json['pickUpDate'] != null
            ? DateTime.parse(json['pickUpDate'])
            : null,
      );
}

class PaymentEntry {
  String deposit;
  String balance;

  PaymentEntry({
    required this.deposit,
    required this.balance,
  });

  Map<String, dynamic> toJson() => {'deposit': deposit, 'balance': balance};
  factory PaymentEntry.fromJson(Map<String, dynamic> json) => PaymentEntry(
        deposit: json['deposit'],
        balance: json['balance'],
      );
}

class ClotthingManager {
  static Future<void> saveClothingItem(
    List<ClothingItem> clothingItems,
  ) async {
    try {
      const baseDir = 'lib/clothesentrymodel/clothingitemstorage';

      final clothingDirPath = path.join(baseDir);

      final clothingDir = Directory(clothingDirPath);

      if (!await clothingDir.exists()) {
        await clothingDir.create(recursive: true);
        if (await clothingDir.exists()) {
          print('Clothing directory created');
        } else {
          print('Failed to create clothing directory');
          return;
        }
      }

      final filePath = path.join(clothingDirPath, 'clothing.json');

      final file = File(filePath);

      final jsonList = clothingItems.map((ci) => ci.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
      print('Clothing item saved');
    } catch (e) {
      print('Error saving clothing item: $e');
      rethrow;
    }
  }

  static Future<List<ClothingItem>> loadClothingItems() async {
    try {
      const baseDir = 'lib/clothesentrymodel/clothingitemstorage';

      final clothingDirPath = path.join(baseDir);
      final filePath = path.join(clothingDirPath, 'clothing.json');
      final file = File(filePath);

      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = json.decode(contents);
        final List<ClothingItem> clothingItems = jsonList
            .map((jsonItem) => ClothingItem.fromJson(jsonItem))
            .toList();
        return clothingItems;
      } else {
        print('No existing clothing item');
        return [];
      }
    } catch (e) {
      print('Error loading clothing item: $e');
      rethrow;
    }
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
