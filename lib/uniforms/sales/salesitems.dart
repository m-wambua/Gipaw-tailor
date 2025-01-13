// Sales Manager class to handle data operations
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';


class SaleItem {
  final String saleId;
  final String uniformItem;
  final String color;
  final String size;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final String date;

  SaleItem({
    required this.saleId,
    required this.uniformItem,
    required this.color,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.date,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      saleId: json['saleId'],
      uniformItem: json['uniformItem'],
      color: json['color'],
      size: json['size'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'],
      totalPrice: json['totalPrice'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saleId': saleId,
      'uniformItem': uniformItem,
      'color': color,
      'size': size,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'date': date,
    };
  }
}

// Sales Manager class to handle data operations


class SalesManager {
  final String filePath;
  List<SaleItem> currentSales = [];
  final _uuid = Uuid();

  SalesManager(this.filePath) {
    loadSales();
  }

  Future<void> loadSales() async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = json.decode(jsonString);
        currentSales = jsonList.map((json) => SaleItem.fromJson(json)).toList();
        // Sort sales by date, most recent first
        currentSales.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (e) {
      print('Error loading sales data: $e');
      // Initialize with empty list if file doesn't exist or has errors
      currentSales = [];
    }
  }

  Future<void> saveSales() async {
    try {
      final file = File(filePath);
      final jsonList = currentSales.map((sale) => sale.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving sales data: $e');
      throw Exception('Failed to save sales data');
    }
  }

  Future<bool> processSale(List<Map<String, dynamic>> saleEntries) async {
    try {
      final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');
      final currentDate = dateFormatter.format(DateTime.now());
      
      for (var entry in saleEntries) {
        final saleItem = SaleItem(
          saleId: _uuid.v4(), // Generate unique ID for each sale
          uniformItem: entry['selectedUniformItem'],
          color: entry['selectedColor'],
          size: entry['selectedSize'] ?? 'N/A',
          quantity: int.parse(entry['numberController'].text),
          unitPrice: int.parse(entry['selectedPrize']),
          totalPrice: entry['calculatedPrice'],
          date: currentDate,
        );
        
        currentSales.add(saleItem);
      }
      
      await saveSales();
      return true;
    } catch (e) {
      print('Error processing sale: $e');
      return false;
    }
  }

  // Get total sales for a specific date range
  double getSalesInRange(DateTime startDate, DateTime endDate) {
    return currentSales
        .where((sale) {
          final saleDate = DateFormat('yyyy-MM-dd HH:mm').parse(sale.date);
          return saleDate.isAfter(startDate) && saleDate.isBefore(endDate);
        })
        .fold(0.0, (sum, sale) => sum + sale.totalPrice);
  }

  // Get total items sold for a specific date range
  int getItemsSoldInRange(DateTime startDate, DateTime endDate) {
    return currentSales
        .where((sale) {
          final saleDate = DateFormat('yyyy-MM-dd HH:mm').parse(sale.date);
          return saleDate.isAfter(startDate) && saleDate.isBefore(endDate);
        })
        .fold(0, (sum, sale) => sum + sale.quantity);
  }

  // Get sales summary by uniform item
  Map<String, dynamic> getSalesSummaryByItem() {
    final summary = <String, dynamic>{};
    
    for (var sale in currentSales) {
      if (!summary.containsKey(sale.uniformItem)) {
        summary[sale.uniformItem] = {
          'totalQuantity': 0,
          'totalValue': 0,
          'sales': 0,
        };
      }
      
      summary[sale.uniformItem]['totalQuantity'] += sale.quantity;
      summary[sale.uniformItem]['totalValue'] += sale.totalPrice;
      summary[sale.uniformItem]['sales']++;
    }
    
    return summary;
  }

  // Get daily sales summary
  Future<Map<String, dynamic>> getDailySalesSummary() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    
    final dailySales = currentSales.where((sale) {
      final saleDate = DateFormat('yyyy-MM-dd HH:mm').parse(sale.date);
      return saleDate.isAfter(startOfDay) && saleDate.isBefore(endOfDay);
    }).toList();
    
    final totalRevenue = dailySales.fold(0, (sum, sale) => sum + sale.totalPrice);
    final totalItems = dailySales.fold(0, (sum, sale) => sum + sale.quantity);
    
    return {
      'totalSales': dailySales.length,
      'totalRevenue': totalRevenue,
      'totalItems': totalItems,
      'averageOrderValue': dailySales.isEmpty ? 0 : totalRevenue / dailySales.length,
    };
  }

  // Search sales by criteria
  List<SaleItem> searchSales({
    String? uniformItem,
    String? color,
    String? size,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return currentSales.where((sale) {
      bool matches = true;
      
      if (uniformItem != null) {
        matches = matches && sale.uniformItem.toLowerCase().contains(uniformItem.toLowerCase());
      }
      
      if (color != null) {
        matches = matches && sale.color.toLowerCase() == color.toLowerCase();
      }
      
      if (size != null) {
        matches = matches && sale.size.toLowerCase() == size.toLowerCase();
      }
      
      if (startDate != null || endDate != null) {
        final saleDate = DateFormat('yyyy-MM-dd HH:mm').parse(sale.date);
        if (startDate != null) {
          matches = matches && saleDate.isAfter(startDate);
        }
        if (endDate != null) {
          matches = matches && saleDate.isBefore(endDate);
        }
      }
      
      return matches;
    }).toList();
  }

  // Delete a sale by ID
  Future<bool> deleteSale(String saleId) async {
    try {
      currentSales.removeWhere((sale) => sale.saleId == saleId);
      await saveSales();
      return true;
    } catch (e) {
      print('Error deleting sale: $e');
      return false;
    }
  }

  // Get sales statistics
  Map<String, dynamic> getSalesStatistics() {
    if (currentSales.isEmpty) {
      return {
        'totalRevenue': 0,
        'totalItems': 0,
        'averageOrderValue': 0,
        'totalSales': 0,
      };
    }

    final totalRevenue = currentSales.fold(0, (sum, sale) => sum + sale.totalPrice);
    final totalItems = currentSales.fold(0, (sum, sale) => sum + sale.quantity);
    
    return {
      'totalRevenue': totalRevenue,
      'totalItems': totalItems,
      'averageOrderValue': totalRevenue / currentSales.length,
      'totalSales': currentSales.length,
    };
  }
}