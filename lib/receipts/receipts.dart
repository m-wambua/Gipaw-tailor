import 'dart:convert';
import 'dart:io';

class ReceiptManager {
  final String receiptFilePath;
  
  ReceiptManager(this.receiptFilePath);
  
  Future<void> saveReceipt(Map<String, dynamic> receiptData) async {
    try {
      final file = File(receiptFilePath);
      List<Map<String, dynamic>> receipts = [];
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        final jsonData = json.decode(contents) as List;
        receipts = jsonData.cast<Map<String, dynamic>>();
      }
      
      receipts.add(receiptData);
      await file.writeAsString(json.encode(receipts));
    } catch (e) {
      throw Exception('Failed to save receipt: $e');
    }
  }
}