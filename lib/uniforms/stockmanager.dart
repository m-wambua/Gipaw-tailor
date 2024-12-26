import 'dart:convert';
import 'dart:io';

class StockItem {
  final String uniformItem;
  final String color;
  final String size;
  final int quantity;
  final int price;
  final String date;

  StockItem({
    required this.uniformItem,
    required this.color,
    required this.size,
    required this.quantity,
    required this.price,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'uniformItem': uniformItem,
        'color': color,
        'size': size,
        'quantity': quantity,
        'price': price,
        'date': date,
      };

  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
        uniformItem: json['uniformItem'],
        color: json['color'],
        size: json['size'],
        quantity: json['quantity'],
        price: json['price'],
        date: json['date'],
      );
}

class StockManager {
  final String filePath;
  List<StockItem> _stockItems = [];

  StockManager(this.filePath) {
    _loadStock();
  }

  Future<void> _loadStock() async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = json.decode(contents);
        _stockItems = jsonList.map((item) => StockItem.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading stock: $e');
    }
  }

  Future<void> _saveStock() async {
    try {
      final file = File(filePath);
      final jsonList = _stockItems.map((item) => item.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving stock: $e');
    }
  }

  Future<void> addNewStock(List<Map<String, dynamic>> entries) async {
    final now = DateTime.now();
    final dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    for (var entry in entries) {
      final newItem = StockItem(
        uniformItem: entry['selectedUniformItem'],
        color: entry['selectedColor'],
        size: entry['selectedSize'] ?? 'N/A',
        quantity: int.parse(entry['numberController'].text),
        price: entry['calculatedPrice'],
        date: dateStr,
      );

      // Check if similar item exists and update quantity
      final existingItemIndex = _stockItems.indexWhere((item) =>
          item.uniformItem == newItem.uniformItem &&
          item.color == newItem.color &&
          item.size == newItem.size);

      if (existingItemIndex != -1) {
        final existingItem = _stockItems[existingItemIndex];
        _stockItems[existingItemIndex] = StockItem(
          uniformItem: existingItem.uniformItem,
          color: existingItem.color,
          size: existingItem.size,
          quantity: existingItem.quantity + newItem.quantity,
          price: newItem.price,
          date: dateStr,
        );
      } else {
        _stockItems.add(newItem);
      }
    }

    await _saveStock();
  }

  Future<bool> processSale(List<Map<String, dynamic>> saleEntries) async {
    // First verify if we have enough stock
    for (var entry in saleEntries) {
      final requestedQuantity = int.parse(entry['numberController'].text);
      final stockItem = _stockItems.firstWhere(
        (item) =>
            item.uniformItem == entry['selectedUniformItem'] &&
            item.color == entry['selectedColor'] &&
            item.size == entry['selectedSize'],
        orElse: () => throw Exception('Item not found in stock'),
      );

      if (stockItem.quantity < requestedQuantity) {
        return false; // Not enough stock
      }
    }

    // If we have enough stock, process the sale
    for (var entry in saleEntries) {
      final requestedQuantity = int.parse(entry['numberController'].text);
      final itemIndex = _stockItems.indexWhere(
        (item) =>
            item.uniformItem == entry['selectedUniformItem'] &&
            item.color == entry['selectedColor'] &&
            item.size == entry['selectedSize'],
      );

      if (itemIndex != -1) {
        final currentItem = _stockItems[itemIndex];
        _stockItems[itemIndex] = StockItem(
          uniformItem: currentItem.uniformItem,
          color: currentItem.color,
          size: currentItem.size,
          quantity: currentItem.quantity - requestedQuantity,
          price: currentItem.price,
          date: currentItem.date,
        );

        // Remove item if quantity becomes 0
        if (_stockItems[itemIndex].quantity == 0) {
          _stockItems.removeAt(itemIndex);
        }
      }
    }

    await _saveStock();
    return true;
  }

  List<StockItem> get currentStock => _stockItems;
}
