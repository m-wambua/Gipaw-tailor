import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gipaw_tailor/signinpage/authorization.dart';
import 'package:gipaw_tailor/signinpage/protectedroutes.dart';
import 'package:gipaw_tailor/signinpage/users.dart';
import 'package:gipaw_tailor/uniformorderdirective/orderauthorization.dart';
import 'package:gipaw_tailor/uniforms/uniforms_data.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum UrgencyLevel {
  low('Low Urgency'),
  normal('Normal Urgency'),
  high('High Urgency'),
  critical('Critical Urgency');

  final String label;
  const UrgencyLevel(this.label);
}

class UniformOrderDirective extends StatefulWidget {
  const UniformOrderDirective({Key? key}) : super(key: key);

  _UniformOrderDirectiveState createState() => _UniformOrderDirectiveState();
}

class _UniformOrderDirectiveState extends State<UniformOrderDirective>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
        allowedRoles: const [UserRole.admin, UserRole.manager],
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text("Uniform Order Directive"),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  text: "Pending Order",
                ),
                Tab(
                  text: "Completed But Waiting Approval",
                ),
                Tab(
                  text: "Approved and Verified Orders",
                )
              ],
            ),
          ),
          body: TabBarView(controller: _tabController, children: [
            const PendingOrderTab(),
            const WaitingApprovalTab(),
            const ApprovedandVerifiedTab(),
          ]),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _uniformOrders();
            },
            tooltip: "make new order",
            child: const Icon(Icons.add),
          ),
        ));
  }

  Future<void> _uniformOrders() async {
    final uniformItems = uniformItemData.keys.toList();
    List<Map<String, dynamic>> entries = [];
    showDialog(
        context: context,
        builder: (BuildContext contetx) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text('Uniform Order Directive'),
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
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child:
                                              DropdownButtonFormField<String>(
                                            decoration: const InputDecoration(
                                                labelText: "Uniform Item"),
                                            items:
                                                uniformItems.map((String item) {
                                              return DropdownMenuItem<String>(
                                                value: item,
                                                child: Text(item),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                entries[index][
                                                        'selectedUniformItem'] =
                                                    newValue;
                                                entries[index]
                                                        ['availableColors'] =
                                                    uniformItemData[newValue]![
                                                        'colors']!;
                                                entries[index]
                                                        ['availableSizes'] =
                                                    uniformItemData[newValue]![
                                                        'sizes']!;

                                                entries[index]
                                                    ['selectedColor'] = null;
                                                entries[index]['selectedSize'] =
                                                    null;
                                              });
                                            },
                                            value: entries[index]
                                                ['selectedUniformItem'],
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child:
                                              DropdownButtonFormField<String>(
                                            decoration: const InputDecoration(
                                                labelText: "Color"),
                                            items: entries[index]
                                                    ['availableColors']
                                                .map<DropdownMenuItem<String>>(
                                                    (color) {
                                              return DropdownMenuItem<String>(
                                                value: color,
                                                child: Text(color),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                entries[index]
                                                        ['selectedColor'] =
                                                    newValue;
                                              });
                                            },
                                            value: entries[index]
                                                ['selectedColor'],
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                          child:
                                              DropdownButtonFormField<String>(
                                            decoration: const InputDecoration(
                                                labelText: "Size"),
                                            items: entries[index]
                                                    ['availableSizes']
                                                .map<DropdownMenuItem<String>>(
                                                    (size) {
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
                                            value: entries[index]
                                                ['selectedSize'],
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                            child: TextFormField(
                                          controller: entries[index]
                                              ['numberController'],
                                          decoration: const InputDecoration(
                                              labelText: "Number"),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Enter a number";
                                            }
                                            if (int.tryParse(value) == null) {
                                              return "Only whole numbers allowed";
                                            }
                                            return null;
                                          },
                                        )),
                                        IconButton(
                                            onPressed: () => _removeEntry(
                                                entries, index, setState),
                                            icon: const Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                            ))
                                      ],
                                    ),
                                  )
                                ],
                              );
                            })),
                    const SizedBox(
                      height: 10,
                    ),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.green,
                      ),
                      label: const Text("Add"),
                      onPressed: () => _addNewEntry(entries, setState),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () async {
                      await _submitOrder(entries);
                    },
                    child: const Text("Send Order")),
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"))
              ],
            );
          });
        });
  }

  Future<void> _submitOrder(List<Map<String, dynamic>> entries) async {
    final TextEditingController _nameController = TextEditingController();

    final ValueNotifier<DateTime?> selectedDateNotifier =
        ValueNotifier<DateTime?>(null);

    final ValueNotifier<TimeOfDay?> selectedTimeNotifier =
        ValueNotifier<TimeOfDay?>(null);

    final ValueNotifier<UrgencyLevel> urgencyNotifier =
        ValueNotifier<UrgencyLevel>(UrgencyLevel.normal);

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please add at least one item to your order')));
      return;
    }

    bool hasInvalidEntries = entries.any((entry) =>
        entry['selectedUniformItem'] == null ||
        entry['selectedColor'] == null ||
        entry['selectedSize'] == null ||
        entry['numberController'].text.isEmpty ||
        int.tryParse(entry['numberController'].text) == null);
    if (hasInvalidEntries) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all fields for each item')));
      return;
    }
    showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(builder: (context, setState) {
            String _calculateSummary() {
              Map<String, List<Map<String, dynamic>>> itemDetails = {};
              Map<String, int> itemCounts = {};

              for (var entry in entries) {
                String itemName =
                    entry['selectedUniformItem'] ?? 'Unknown Item';
                String size = entry['selectedSize'] ?? 'N/A';
                String color = entry['selectedColor'] ?? 'N/A';
                int quantity =
                    int.tryParse(entry['numberController'].text) ?? 0;

                itemCounts[itemName] = (itemCounts[itemName] ?? 0) + 1;

                if (!itemDetails.containsKey(itemName)) {
                  itemDetails[itemName] = [];
                }

                itemDetails[itemName]!.add({
                  'size': size,
                  'color': color,
                  'quantity': quantity,
                });
              }

              return itemDetails.entries.map((entry) {
                String itemName = entry.key;
                List<Map<String, dynamic>> variants = entry.value;

                // Aggregate quantities for the item
                int totalQuantity = variants.fold(
                    0, (sum, variant) => sum + (variant['quantity'] as int));

                // Create a detailed description of variants
                String variantDetails = variants.map((variant) {
                  return '(Size: ${variant['size']}, Color: ${variant['color']}, Qty: ${variant['quantity']})';
                }).join(', ');

                return '$totalQuantity x $itemName $variantDetails';
              }).join('\n');
            }

            return AlertDialog(
              title: Text('Order Summary and Submission'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_calculateSummary()),
                    SizedBox(
                      height: 16,
                    ),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                          labelText: 'Name', hintText: 'Who is to do it?'),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      children: [
                        Text('Select Date: '),
                        TextButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (picked != null) {
                              selectedDateNotifier.value = picked;
                            }
                          },
                          child: ValueListenableBuilder<DateTime?>(
                            valueListenable: selectedDateNotifier,
                            builder: (context, selectedDate, child) {
                              return Text(
                                selectedDate == null
                                    ? 'Choose Date'
                                    : DateFormat('yyyy-MM-dd')
                                        .format(selectedDate),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Select Time: '),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              selectedTimeNotifier.value = picked;
                            }
                          },
                          child: ValueListenableBuilder<TimeOfDay?>(
                            valueListenable: selectedTimeNotifier,
                            builder: (context, selectedTime, child) {
                              return Text(
                                selectedTime == null
                                    ? 'Choose Time'
                                    : selectedTime.format(context),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text('Select Urgency Level: '),
                        DropdownButton<UrgencyLevel>(
                          value: urgencyNotifier.value,
                          items: UrgencyLevel.values.map((level) {
                            return DropdownMenuItem<UrgencyLevel>(
                              value: level,
                              child: Text(level.label),
                            );
                          }).toList(),
                          onChanged: (UrgencyLevel? newValue) {
                            if (newValue != null) {
                              urgencyNotifier.value = newValue;
                            }
                          },
                        )
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate and process submission
                    if (_nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a name')),
                      );
                      return;
                    }

                    if (selectedDateNotifier.value == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a date')),
                      );
                      return;
                    }

                    if (selectedTimeNotifier.value == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please select a time')),
                      );
                      return;
                    }

                    // Construct final order object

                    List<UniformOrderItem> orderItems = entries
                        .map((entry) => UniformOrderItem.fromMap(entry))
                        .toList();

                    final orderId =
                        "ORDU${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

                    final newOrder = UniformOrder(
                      id: orderId,
                      items: orderItems,
                      tailorName: _nameController.text,
                      scheduledDate: selectedDateNotifier.value!,
                      scheduledTime: selectedTimeNotifier.value!,
                      urgencyLevel: urgencyNotifier.value,
                    );

                    // TODO: Add your order submission logic here
                    // For example: _sendOrderToBackend(order);
                    Provider.of<OrdersProvider>(context, listen: false)
                        .addOrder(newOrder);

                    // Close both dialogs
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop();

                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('Submit Order'),
                ),
              ],
            );
          });
        });
  }

  void _addNewEntry(List<Map<String, dynamic>> entries, Function setState) {
    setState(() {
      entries.add({
        'selectedUniformItem': null,
        'selectedColor': null,
        'selectedSize': null,
        'availableColors': [],
        'availableSizes': [],
        'numberController': TextEditingController(),
      });
    });
  }

  void _removeEntry(
      List<Map<String, dynamic>> entries, int index, Function setState) {
    setState(() {
      entries.removeAt(index);
    });
  }
}

class PendingOrderTab extends StatelessWidget {
  const PendingOrderTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, orderProvider, child) {
        final pendingOrders = orderProvider.pendingOrders;

        if (pendingOrders.isEmpty) {
          return Center(child: Text('No pending orders'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: pendingOrders.length,
          itemBuilder: (context, index) {
            final order = pendingOrders[index];

            return GestureDetector(
              onTap: () => _showCompletionDialog(context, order),
              child: Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _getUrgencyColor(order.urgencyLevel),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          _buildStatusChip(order.status),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text('Tailor: ${order.tailorName}'),
                      Text(
                          'Due: ${DateFormat('MMM dd, yyyy').format(order.scheduledDate)} at ${order.scheduledTime.format(context)}'),
                      Text('Urgency: ${order.urgencyLevel.label}'),
                      SizedBox(height: 8),
                      Divider(),
                      SizedBox(height: 8),
                      Text('Items:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...order.items.map(
                        (item) => Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '${item.quantity}x ${item.uniformName} (${item.size}, ${item.color})',
                          ),
                        ),
                      ),
                      if (order.status == OrderStatus.partiallyCompleted) ...[
                        SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: order.completionPerentage / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(
                              _getUrgencyColor(order.urgencyLevel)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Completion: ${order.totalCompletedQuantity}/${order.totalOrderQuantity} (${order.completionPerentage.toStringAsFixed(1)}%)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Tap to update status',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Show dialog for marking an order as completed
  void _showCompletionDialog(BuildContext context, UniformOrder order) {
    final fullCompletionSelected = ValueNotifier<bool>(true);
    final Map<String, TextEditingController> completedControllers = {};

    // Initialize controllers for partial completion
    for (var item in order.items) {
      final key = '${item.uniformName}-${item.size}-${item.color}';
      completedControllers[key] =
          TextEditingController(text: item.quantity.toString());
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Order Status'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.id}'),
                    SizedBox(height: 16),
                    Text('Mark as:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: fullCompletionSelected.value,
                          onChanged: (value) {
                            setState(() {
                              fullCompletionSelected.value = value!;
                            });
                          },
                        ),
                        Text('Fully Completed'),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: fullCompletionSelected.value,
                          onChanged: (value) {
                            setState(() {
                              fullCompletionSelected.value = value!;
                            });
                          },
                        ),
                        Text('Partially Completed'),
                      ],
                    ),
                    if (!fullCompletionSelected.value) ...[
                      SizedBox(height: 16),
                      Text('Enter completed quantities:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ...order.items.map((item) {
                        final key =
                            '${item.uniformName}-${item.size}-${item.color}';
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                    '${item.uniformName} (${item.size}, ${item.color})'),
                              ),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: completedControllers[key],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Qty',
                                    suffixText: '/ ${item.quantity}',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (fullCompletionSelected.value) {
                      // If fully completed, use the original items
                      Provider.of<OrdersProvider>(context, listen: false)
                          .markOrderAsCompleted(
                        order.id,
                        order.items,
                        isfullCompleted: true,
                      );
                    } else {
                      // For partial completion, create new items with entered quantities
                      List<UniformOrderItem> completedItems = [];

                      for (var item in order.items) {
                        final key =
                            '${item.uniformName}-${item.size}-${item.color}';
                        final controller = completedControllers[key]!;
                        final completedQty = int.tryParse(controller.text) ?? 0;

                        if (completedQty > 0) {
                          completedItems.add(UniformOrderItem(
                            uniformName: item.uniformName,
                            size: item.size,
                            color: item.color,
                            quantity: completedQty,
                          ));
                        }
                      }

                      Provider.of<OrdersProvider>(context, listen: false)
                          .markOrderAsCompleted(
                        order.id,
                        completedItems,
                        isfullCompleted: false,
                      );
                    }

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order status updated')),
                    );
                  },
                  child: Text('Update Status'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Get color based on urgency level
  Color _getUrgencyColor(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.low:
        return Colors.green;
      case UrgencyLevel.normal:
        return Colors.blue;
      case UrgencyLevel.high:
        return Colors.orange;
      case UrgencyLevel.critical:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  // Build a status chip
  Widget _buildStatusChip(OrderStatus status) {
    Color chipColor;
    String label;

    switch (status) {
      case OrderStatus.pending:
        chipColor = Colors.orange;
        label = 'Pending';
        break;
      case OrderStatus.partiallyCompleted:
        chipColor = Colors.amber;
        label = 'Partial';
        break;
      case OrderStatus.completedPendingApproval:
        chipColor = Colors.lightBlue;
        label = 'Completed';
        break;
      case OrderStatus.approvedAndVerified:
        chipColor = Colors.green;
        label = 'Approved';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        border: Border.all(color: chipColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class WaitingApprovalTab extends StatelessWidget {
  const WaitingApprovalTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, orderProvider, child) {
        final completedOrders = orderProvider.completedPendingApprovalOrders;

        if (completedOrders.isEmpty) {
          return Center(child: Text('No orders pending approval'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: completedOrders.length,
          itemBuilder: (context, index) {
            final order = completedOrders[index];

            return GestureDetector(
              onTap: () => _showApprovalDialog(context, order),
              child: Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          _buildStatusChip(order.status),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text('Customer: ${order.tailorName}'),
                      Text(
                          'Completed on: ${DateFormat('MMM dd, yyyy').format(order.completionDate!)}'),
                      SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: order.completionPerentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Completion: ${order.totalCompletedQuantity}/${order.totalOrderQuantity} (${order.completionPerentage.toStringAsFixed(1)}%)',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(height: 8),
                      Divider(),
                      SizedBox(height: 8),
                      Text('Completed Items:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...order.completedItems.map(
                        (item) => Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '${item.quantity}x ${item.uniformName} (${item.size}, ${item.color})',
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Tap to approve',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Show dialog for approving an order
  void _showApprovalDialog(BuildContext context, UniformOrder order) {
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Approve Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${order.id}'),
                SizedBox(height: 16),
                Text('Completion Summary:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    '${order.totalCompletedQuantity} of ${order.totalOrderQuantity} items completed (${order.completionPerentage.toStringAsFixed(1)}%)'),
                SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Final Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter the final price')),
                  );
                  return;
                }

                final price = double.tryParse(priceController.text);
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid price')),
                  );
                  return;
                }

                // Approve the order
                final ordersProvider =
                    Provider.of<OrdersProvider>(context, listen: false);
                ordersProvider.approvedOrder(order.id, price);

                // Update uniform stock data
                //  ordersProvider.updateUni(order);

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order approved successfully')),
                );
              },
              child: Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color chipColor;
    String label;

    switch (status) {
      case OrderStatus.pending:
        chipColor = Colors.orange;
        label = 'Pending';
        break;
      case OrderStatus.partiallyCompleted:
        chipColor = Colors.amber;
        label = 'Partial';
        break;
      case OrderStatus.completedPendingApproval:
        chipColor = Colors.lightBlue;
        label = 'Completed';
        break;
      case OrderStatus.approvedAndVerified:
        chipColor = Colors.green;
        label = 'Approved';
        break;
      default:
        throw Exception('Invalid OrderStatus: $status');
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        border: Border.all(color: chipColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ApprovedandVerifiedTab extends StatelessWidget {
  const ApprovedandVerifiedTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
