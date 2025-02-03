import 'package:flutter/material.dart';
import 'package:gipaw_tailor/uniforms/stockmanager.dart';
import 'package:gipaw_tailor/uniforms/uniforms_data.dart';
import 'package:intl/intl.dart';

class StockViewWrapper extends StatefulWidget {
  final String stockFilePath;

  const StockViewWrapper({
    super.key,
    required this.stockFilePath,
  });

  @override
  State<StockViewWrapper> createState() => _StockViewWrapperState();
}

class _StockViewWrapperState extends State<StockViewWrapper> {
  late StockManager _stockManager;
  List<StockItem> _stockItems = [];
  bool _isLoading = true;
  final bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeStock();
  }

  Future<void> _initializeStock() async {
    _stockManager = StockManager(widget.stockFilePath);
    // Wait a brief moment for the stock to load
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() {
      _stockItems = _stockManager.currentStock;
      _isLoading = false;
    });
  }

  Future<void> _refreshStock() async {
    setState(() {
      _isLoading = true;
    });
    await _initializeStock();
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

    return StockViewPage(
      stockItems: _stockItems,
      onRefresh: _refreshStock,
    );
  }
}

class StockViewPage extends StatefulWidget {
  final List<StockItem> stockItems;
  final Future<void> Function() onRefresh;

  const StockViewPage({
    super.key,
    required this.stockItems,
    required this.onRefresh,
  });

  @override
  State<StockViewPage> createState() => _StockViewPageState();
}

class _StockViewPageState extends State<StockViewPage> {
  final currencyFormatter = NumberFormat.currency(
    symbol: "KSH",
    decimalDigits: 0,
  );

  Widget _buildStatusIndicator(int quanity) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String statusText;

    if (quanity <= 0) {
      backgroundColor = Colors.red;
      statusText = "Out of Stock";
    } else if (quanity <= 5) {
      backgroundColor = Colors.orange;
      statusText = "Low Stock";
    } else {
      backgroundColor = Colors.green;
      statusText = "In Stock";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        statusText,
        style: TextStyle(
            color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Inventory"),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryCard(
                      "Total Items",
                      widget.stockItems.length.toString(),
                      Icons.inventory,
                      Colors.blue,
                    ),
                    _buildSummaryCard(
                      "Total Quantity",
                      widget.stockItems
                          .fold<int>(
                            0,
                            (sum, item) => sum + item.quantity,
                          )
                          .toString(),
                      Icons.shopping_bag,
                      Colors.green,
                    ),
                    _buildSummaryCard(
                      "Total Value",
                      currencyFormatter.format(
                        widget.stockItems.fold<int>(
                          0,
                          (sum, item) => sum + (item.price * item.quantity),
                        ),
                      ),
                      Icons.attach_money,
                      Colors.orange,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
                child: Card(
              child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Item")),
                        DataColumn(label: Text("Color")),
                        DataColumn(label: Text("Size")),
                        DataColumn(label: Text("Quantity")),
                        DataColumn(label: Text("Unit Price")),
                        DataColumn(label: Text('Stock Status')),
                        DataColumn(label: Text("Total Value")),
                        DataColumn(label: Text("Date Added")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rows: widget.stockItems
                          .map((item) => DataRow(
                                cells: [
                                  DataCell(Text(item.uniformItem)),
                                  DataCell(Text(item.color)),
                                  DataCell(Text(item.size)),
                                  DataCell(Text(item.quantity.toString())),
                                  DataCell(Text(
                                      currencyFormatter.format((item.price)))),
                                  DataCell(
                                      _buildStatusIndicator(item.quantity)),
                                  DataCell(Text(currencyFormatter
                                      .format(item.price * item.quantity))),
                                  DataCell(Text(item.date)),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          onPressed: () {},
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                            size: 20,
                                          )),
                                      IconButton(
                                          onPressed: () {},
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ))
                                    ],
                                  ))
                                ],
                              ))
                          .toList(),
                    ),
                  )),
            ))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _uniformStock();
        },
        tooltip: 'Add New Stock',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(
            height: 8,
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          )
        ],
      ),
    );
  }

  Future<void> _uniformStock() async {
    final uniformItems = uniformItemData.keys.toList();

    // List to hold multiple entries
    List<Map<String, dynamic>> entries = [];
    final stockManager = StockManager('lib/uniforms/stock/stock.json');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void addNewEntry() {
              setState(() {
                entries.add({
                  'selectedUniformItem': null,
                  'selectedColor': null,
                  'selectedSize': null,
                  'selectedPrize': null,
                  'price': null,
                  'availableColors': [],
                  'availableSizes': [],
                  'availablePrizes': [],
                  'numberController': TextEditingController(),
                  'priceController': TextEditingController(),
                  'calculatedPrice': 0,
                });
              });
            }

            void removeEntry(int index) {
              setState(() {
                entries.removeAt(index);
              });
            }

            void updateCalculatedPrice(int index) {
              final entry = entries[index];
              final selectedUnitPrice =
                  int.tryParse(entry['selectedPrize'] ?? '0') ?? 0;
              final quantity =
                  int.tryParse(entry['numberController'].text.trim()) ?? 0;
              final calculatedTotalPrice = selectedUnitPrice * quantity;

              setState(() {
                entry['price'] = selectedUnitPrice;
                entry['calculatedPrice'] = calculatedTotalPrice;
                entry['priceController'].text = calculatedTotalPrice.toString();
              });
            }

            int calculateTotalPrice() {
              return entries.fold<int>(
                0,
                (sum, entry) => sum + (entry['calculatedPrice'] as int? ?? 0),
              );
            }

            return AlertDialog(
              title: const Text("Uniform Stock"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                        labelText: "Uniform Item"),
                                    items: uniformItems.map((String item) {
                                      return DropdownMenuItem<String>(
                                        value: item,
                                        child: Text(item),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        entries[index]['selectedUniformItem'] =
                                            newValue;
                                        entries[index]['availableColors'] =
                                            uniformItemData[newValue]![
                                                'colors']!;
                                        entries[index]['availableSizes'] =
                                            uniformItemData[newValue]![
                                                'sizes']!;
                                        entries[index]['availablePrizes'] =
                                            uniformItemData[newValue]![
                                                'prizes']!;
                                        entries[index]['selectedColor'] = null;
                                        entries[index]['selectedSize'] = null;
                                        entries[index]['selectedPrize'] = null;
                                        updateCalculatedPrice(index);
                                      });
                                    },
                                    value: entries[index]
                                        ['selectedUniformItem'],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                        labelText: "Color"),
                                    items: entries[index]['availableColors']
                                        .map<DropdownMenuItem<String>>((color) {
                                      return DropdownMenuItem<String>(
                                        value: color,
                                        child: Text(color),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        entries[index]['selectedColor'] =
                                            newValue;
                                      });
                                    },
                                    value: entries[index]['selectedColor'],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                        labelText: "Size"),
                                    items: entries[index]['availableSizes']
                                        .map<DropdownMenuItem<String>>((size) {
                                      return DropdownMenuItem<String>(
                                        value: size,
                                        child: Text(size),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        entries[index]['selectedSize'] =
                                            newValue;
                                      });
                                    },
                                    value: entries[index]['selectedSize'],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: entries[index]
                                        ['numberController'],
                                    decoration: const InputDecoration(
                                        labelText: "Number"),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      updateCalculatedPrice(index);
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter a number';
                                      }
                                      if (int.tryParse(value) == null) {
                                        return 'Only whole numbers allowed';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                        labelText: "Unit Prize"),
                                    items: entries[index]['availablePrizes']
                                        .map<DropdownMenuItem<String>>((prize) {
                                      return DropdownMenuItem<String>(
                                        value: prize,
                                        child: Text(prize),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        entries[index]['selectedPrize'] =
                                            newValue;
                                        updateCalculatedPrice(index);
                                      });
                                    },
                                    value: entries[index]['selectedPrize'],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () => removeEntry(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      icon: const Icon(Icons.add, color: Colors.green),
                      label: const Text("Add"),
                      onPressed: addNewEntry,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    bool isValid = true;
                    for (var entry in entries) {
                      if (entry['selectedUniformItem'] == null ||
                          entry['selectedColor'] == null ||
                          entry['numberController'].text.isEmpty ||
                          int.tryParse(entry['numberController'].text) ==
                              null ||
                          entry['selectedSize'] == null ||
                          entry['price'] == null) {
                        isValid = false;
                        break;
                      }
                    }

                    if (isValid) {
                      await stockManager.addNewStock(entries);
                      for (var entry in entries) {
                        print('Item: ${entry['selectedUniformItem']}');
                        print('Color: ${entry['selectedColor']}');
                        print('Size: ${entry['selectedSize']}');
                        print('Number: ${entry['numberController'].text}');

                        print('Price: ${entry['selectedPrize']}');
                      }
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              CircularProgressIndicator.adaptive(),
                              SizedBox(
                                width: 10,
                              ),
                              Text("Updating Stock...")
                            ],
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      await widget.onRefresh();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Stock updated successfully",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      print('Ensure all fields are filled with valid inputs.');
                    }
                  },
                  child: const Text("Submit"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
