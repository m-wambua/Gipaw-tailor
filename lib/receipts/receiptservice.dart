import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gipaw_tailor/receipts/receipts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptService {
  static const String _storageKey = 'receipts';

  Future<void> saveReceipt(Receipt receipt) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> receipts = prefs.getStringList(_storageKey) ?? [];

    // Convert items to a serializable format
    List<Map<String, dynamic>> serializedItems = receipt.items.map((item) {
      return {
        'selectedUniformItem': item['selectedUniformItem'],
        'selectedColor': item['selectedColor'],
        'selectedSize': item['selectedSize'],
        'selectedPrize': item['selectedPrize'],
        'quantity':
            item['numberController'].text, // Get text value from controller
        'price': item['priceController'].text, // Get text value from controller
        'calculatedPrice': item['calculatedPrice'],
      };
    }).toList();

    // Create the receipt JSON
    Map<String, dynamic> receiptJson = {
      'receiptNumber': receipt.receiptNumber,
      'timestamp': receipt.timestamp.toIso8601String(),
      'items': serializedItems, // Use the serialized items
      'totalAmount': receipt.totalAmount,
      'payments': receipt.payments
          .map((payment) => {
                'method': payment.method,
                'amount': payment.amount,
                'givenAmount': payment.givenAmount,
              })
          .toList(),
      'customerDetails': receipt.customerDetails != null
          ? {
              'name': receipt.customerDetails!.name,
              'email': receipt.customerDetails!.email,
              'phone': receipt.customerDetails!.phone,
            }
          : null,
      'servedBy': receipt.servedBy,
    };

    receipts.add(jsonEncode(receiptJson));
    await prefs.setStringList(_storageKey, receipts);
  }

  Future<List<Receipt>> getAllReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> receipts = prefs.getStringList(_storageKey) ?? [];

    return receipts.map((receiptString) {
      Map<String, dynamic> receiptJson = jsonDecode(receiptString);

      // Convert serialized items back to the expected format
      List<Map<String, dynamic>> items =
          (receiptJson['items'] as List).map((item) {
        return {
          'selectedUniformItem': item['selectedUniformItem'],
          'selectedColor': item['selectedColor'],
          'selectedSize': item['selectedSize'],
          'selectedPrize': item['selectedPrize'],
          'numberController': TextEditingController(text: item['quantity']),
          'priceController': TextEditingController(text: item['price']),
          'calculatedPrice': item['calculatedPrice'],
        };
      }).toList();

      return Receipt(
        receiptNumber: receiptJson['receiptNumber'],
        timestamp: DateTime.parse(receiptJson['timestamp']),
        items: items,
        totalAmount: receiptJson['totalAmount'],
        payments: (receiptJson['payments'] as List)
            .map((payment) => PaymentEntryReciept(
                  method: payment['method'],
                  amount: payment['amount'],
                  givenAmount: payment['givenAmount'],
                ))
            .toList(),
        customerDetails: receiptJson['customerDetails'] != null
            ? CustomerDetails(
                name: receiptJson['customerDetails']['name'],
                email: receiptJson['customerDetails']['email'],
                phone: receiptJson['customerDetails']['phone'],
              )
            : null,
        servedBy: receiptJson['servedBy'],
      );
    }).toList();
  }

  Future<Receipt?> getReceiptByNumber(String receiptNumber) async {
    final receipts = await getAllReceipts();
    try {
      return receipts.firstWhere(
        (receipt) => receipt.receiptNumber == receiptNumber,
      );
    } catch (e) {
      return null;
    }
  }
}
