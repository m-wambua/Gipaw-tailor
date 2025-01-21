import 'package:flutter/material.dart';
import 'package:gipaw_tailor/uniforms/sales/salesitems.dart';
import 'package:intl/intl.dart';
class SalesViewWrapper extends StatefulWidget {
  final String salesFilePath;

  const SalesViewWrapper({
    super.key,
    required this.salesFilePath,
  });

  @override
  State<SalesViewWrapper> createState() => _SalesViewWrapperState();
}

class _SalesViewWrapperState extends State<SalesViewWrapper> {
  late SalesManager _salesManager;
  List<SaleItem> _salesItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSales();
  }

  Future<void> _initializeSales() async {
    _salesManager = SalesManager(widget.salesFilePath);
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _salesItems = _salesManager.currentSales;
      _isLoading = false;
    });
  }

  Future<void> _refreshSales() async {
    setState(() {
      _isLoading = true;
    });
    await _initializeSales();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SalesViewPage(
      salesItems: _salesItems,
      onRefresh: _refreshSales,
    );
  }
}
class SalesViewPage extends StatefulWidget {
  final List<SaleItem> salesItems;
  final Future<void> Function() onRefresh;

  const SalesViewPage({
    super.key,
    required this.salesItems,
    required this.onRefresh,
  });

  @override
  State<SalesViewPage> createState() => _SalesViewPageState();
}

class _SalesViewPageState extends State<SalesViewPage> {
  final currencyFormatter = NumberFormat.currency(
    symbol: "KSH",
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.salesItems.length;
    final totalQuantity = widget.salesItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final totalValue = widget.salesItems.fold<int>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    return Scaffold(
      appBar: AppBar( 
        title: const Text("Sales History"),
        actions: [ 
          IconButton(onPressed: widget.onRefresh,
           icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [ 
          Card(
            child: Padding(padding: const EdgeInsets.all(16.0),
            child: Row( 
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard(
                  "Total Sales",
                  totalItems.toString(),
                  Icons.receipt_long,
                  Colors.purple,
                ),
_buildSummaryCard( 
  "Items Sold",
  totalQuantity.toString(),
  Icons.shopping_cart,
  Colors.green,
),

                _buildSummaryCard( 
                  "Revenue",
                  currencyFormatter.format(totalValue),
                  Icons.payments,
                  Colors.orange
                )
              ],
            ),),
          ),
          const SizedBox(height: 10,),
          Expanded( 
            child: Card( 
              child: SingleChildScrollView( 
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView( 
                  scrollDirection: Axis.horizontal,
                  child: DataTable( 
                    columns: const [ 
                      DataColumn(label: Text("Sale Id")),
                      DataColumn(label: Text("Item")),
                      DataColumn(label: Text("Color")),
                      DataColumn(label: Text("Size")),
                      DataColumn(label: Text("Quantity")),
                      DataColumn(label: Text("Unit Price")),
                      DataColumn(label: Text("Total Value")),
                      DataColumn(label: Text("Date")),
                      
                    ],
                    rows: widget.salesItems.map((sale)=> DataRow( 
                      cells: [ 
                        DataCell(Text(sale.saleId)),
                        DataCell(Text(sale.uniformItem)),
                        DataCell(Text(sale.color)),
                        DataCell(Text(sale.size)),
                        DataCell(Text(sale.quantity.toString())),
                        DataCell(Text(currencyFormatter.format(sale.unitPrice))),
                        DataCell(Text(currencyFormatter.format(sale.totalPrice))),
                        DataCell(Text(sale.date)),
                      ],
                    )).toList(),
                  ),
                )
              )
            )
          )
        ],
      ),
      ),
    );
  }

  Widget _buildSummaryCard(String title,String value, IconData icon, Color color){
    return Container( 
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration( 
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Column( 
        mainAxisSize: MainAxisSize.min,
        children: [ 
          Icon( icon, color: color,),
          const SizedBox(height: 8,),
          Text( 
            title,
            style: TextStyle( 
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4,),
          Text(value,
          style: const TextStyle(fontWeight: FontWeight.bold,
          fontSize: 16,),)
        ],
      ),
    );
  }
}
