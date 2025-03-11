import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gipaw_tailor/labelling/labellingmethod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class LabellingPage extends StatefulWidget {
  @override
  _LabellingPageState createState() => _LabellingPageState();
}

class _LabellingPageState extends State<LabellingPage> {
  @override
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _chargesController = TextEditingController();
  final _labelController = TextEditingController();
  List<LabelOrder> labelOrders = [];

  LabelOrder currentOrder = LabelOrder(
      orderNumber: '',
      createdAt: DateTime.now(),
      customerName: '',
      customerPhoneNumber: '',
      labelType: '',
      notes: '',
      item: '',
      label: '',
      totalAmount: 0.0,
      payments: [],
      createdBy: '',
      status: LabelOrderStatus.pending,
      fufillmentDate: null);

  List<Uint8List> _multipleImages = [];
  final ImagePicker _picker = ImagePicker();

  Future _loadLabelOrders() async {
    try {
      final loadedLabelOrders = await LabelService().getAllLabelOrders();
      setState(() {
        labelOrders = loadedLabelOrders;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error loadinf Label Items")));
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Labelling Page'),
      ),
      body: Column(
        children: [
          Expanded(
              child: labelOrders.isEmpty
                  ? const Center(
                      child:
                          Text("No Label Item added yet. Add your first one "))
                  : ListView.builder(
                      itemCount: labelOrders.length,
                      itemBuilder: (context, index) {
                        final labelOrder = labelOrders[index];
                        return GestureDetector(
                          child: buildLabelItemCard(labelOrder),
                        );
                      }))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _newLabel('New Label Order', existingOrder: currentOrder);
        },
        tooltip: 'New Label',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget buildLabelItemCard(LabelOrder labelOrder) {
    double totalDeposited = labelOrder.payments
        .map((entry) => double.parse((entry.amount).toStringAsFixed(2)))
        .fold(0, (a, b) => a + b);

    double originalCharges =
        double.parse((labelOrder.totalAmount).toStringAsFixed(2));
    double remainingBalance = originalCharges = totalDeposited;
    List<Uint8List> orderImages = labelOrder.imageUrls.map((img) {
      if (img != null && img.startsWith("/")) {
        File file = File(img!);
        if (file.existsSync()) {
          return file.readAsBytesSync();
        } else {
          return Uint8List(0);
        }
      } else {
        return base64Decode(img!);
      }
    }).toList();

    return Card(
      child: ExpansionTile(
          title: Text(labelOrder.customerName),
          subtitle: Text('Phone Number: ${labelOrder.customerPhoneNumber}'),
          children: [
            ListTile(
              title: Text(
                  'Label Type: ${labelOrder.labelType == true ? " Embroidery" : "Other"}'),
            ),
            ListTile(
              title: Text("Notes: ${labelOrder.notes}"),
            ),
            ElevatedButton(
                onPressed: () async {
                  final images = await _loadImagesForOrder(labelOrder);
                  setState(() {
                    orderImages = images;
                  });
                },
                child: const Text('Load Sample')),
            SizedBox(
                height: 200,
                child: orderImages.isEmpty
                    ? const Center(child: Text('No Image Selected'))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: orderImages.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _openFullScreenImage(context, orderImages, index);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Image.memory(orderImages[index]),
                            ),
                          );
                        })),
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Item: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ...labelOrder.item.split(',').asMap().entries.map((entry) {
                      int index = entry.key;
                      String item = entry.value.trim();
                      String label = labelOrder.label.split(',')[index].trim();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Text(
                              '$item: ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                            ),
                            Text(
                              label,
                              style: const TextStyle(color: Colors.black54),
                            )
                          ],
                        ),
                      );
                    })
                  ],
                )),
            ListTile(
              title: Text('Charges: ${labelOrder.totalAmount}'),
            ),
            ListTile(
              title: Text('Deposit Piad: ${totalDeposited.toStringAsFixed(2)}'),
            ),
            _buildBalanceInfoLabels(labelOrder),
            ExpansionTile(
              title: Text(
                  "Payment History(${labelOrder.payments.length} entries)"),
              children: labelOrder.payments
                  .map((entry) => ListTile(
                        title: Text(
                          ("Deposit: ${entry.amount}"),
                        ),
                        subtitle: Text(
                            "Type: ${entry.paymentType}, Date: ${DateFormat('yyyy-MM-dd').format(entry.paymentDate)}"),
                      ))
                  .toList(),
            ),
            ListTile(
              title: Text(
                  'Pick Up Date: ${labelOrder.fufillmentDate?.toIso8601String() ?? "Not Scheduled"}'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: () {
                      _sendPickUpNotification(labelOrder);
                    },
                    child: const Text('Ready for pickup')),
                ElevatedButton(
                    onPressed: () {
                      _showUpdatePaymentDialog(labelOrder);
                    },
                    child: const Text('Update Payment'))
              ],
            )
          ]),
    );
  }

  void _sendPickUpNotification(LabelOrder labelOrder) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Pickup notification sent to ${labelOrder.customerName}")));
    } catch (e) {
      print('Notification error: $e');
    }
  }

  void _showUpdatePaymentDialog(LabelOrder labelOrder) async {
    final depositController = TextEditingController();
    final paymentTypeController = TextEditingController(text: "Cash");
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Update Payment for ${labelOrder.customerName}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: depositController,
                  decoration: const InputDecoration(
                      labelText: "Deposit",
                      hintText: "Enter Deposit amount",
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(
                  height: 10,
                ),
                DropdownButtonFormField<String>(
                  value: paymentTypeController.text,
                  decoration: const InputDecoration(labelText: "Payment Type"),
                  items: ["Cash", "Card", "Bank Transfer", "Mpesa"].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    paymentTypeController.text = value!;
                  },
                )
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () {
                    _processPayment(labelOrder, depositController.text,
                        paymentTypeController.text);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Add Payment"))
            ],
          );
        });
  }

  void _processPayment(
      LabelOrder labelOrder, String depositAmount, String paymentType) async {
    try {
      final double amount = double.parse(depositAmount);

      final double newTotalPaid = labelOrder.totalPaid + amount;

      final LabellingPaymentStatus paymentStatus = _determinePaymentStatus(
          totalAmount: labelOrder.totalAmount,
          currentlyPaid: labelOrder.totalPaid,
          newPaymentAmount: amount);

      final String paymentId =
          LabelService().generatePaymentId(labelOrder.orderNumber);
      final String? receiptNumber =
          paymentStatus == LabellingPaymentStatus.finalpayment
              ? 'RCP-$paymentId'
              : null;

      final LabelPayment newPayment = LabelPayment(
          amount: amount,
          paymentDate: DateTime.now(),
          paymentType: paymentType,
          paymentId: paymentId,
          status: paymentStatus,
          recordedBy: labelOrder.createdBy,
          receiptNumber: receiptNumber);
      final updatePayments = [...labelOrder.payments, newPayment];

      final LabelOrderStatus newStatus = _determineOrderStatus(
          totalAmount: labelOrder.totalAmount, totalPaid: newTotalPaid);

      final updateOrder = LabelOrder(
          orderNumber: labelOrder.orderNumber,
          createdAt: labelOrder.createdAt,
          customerName: labelOrder.customerName,
          customerPhoneNumber: labelOrder.customerPhoneNumber,
          labelType: labelOrder.labelType,
          notes: labelOrder.notes,
          item: labelOrder.item,
          label: labelOrder.label,
          totalAmount: labelOrder.totalAmount,
          payments: updatePayments,
          createdBy: labelOrder.createdBy,
          fufillmentDate: labelOrder.fufillmentDate);
      await LabelService().saveLabelOrder(updateOrder);
      setState(() {
        _loadLabelOrders();
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment of $depositAmount processed succesffully')));
    } catch (e) {
      print("Error Processing payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error Processing payment")));
    }
  }

  LabellingPaymentStatus _determinePaymentStatus({
    required double totalAmount,
    required double currentlyPaid,
    required double newPaymentAmount,
  }) {
    final double totalAfterPayment = currentlyPaid + newPaymentAmount;

    if (currentlyPaid == 0) {
      return LabellingPaymentStatus.deposit;
    } else if (totalAfterPayment >= totalAmount) {
      return LabellingPaymentStatus.finalpayment;
    } else {
      return LabellingPaymentStatus.partial;
    }
  }

  LabelOrderStatus _determineOrderStatus({
    required double totalAmount,
    required double totalPaid,
  }) {
    if (totalPaid >= totalAmount) {
      return LabelOrderStatus.paid;
    } else if (totalPaid > 0) {
      return LabelOrderStatus.partial;
    } else {
      return LabelOrderStatus.pending;
    }
  }

  Widget _buildBalanceInfoLabels(LabelOrder order) {
    final double remainingBalance = order.remainingBalance;
    final bool isFullyPaid = order.isFullyPaid;

    // Find the last payment that has a receipt number (if any)
    final receiptPayment = order.payments.lastWhere(
        (payment) => payment.receiptNumber != null,
        orElse: () => LabelPayment(
            amount: 0,
            paymentDate: DateTime.now(),
            paymentType: '',
            paymentId: '',
            status: LabellingPaymentStatus.partial,
            recordedBy: '',
            receiptNumber: null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(
            'Remaining Balance: ${remainingBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isFullyPaid ? Colors.green : Colors.red,
            ),
          ),
          subtitle: isFullyPaid
              ? const Text(
                  'FULLY PAID',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
          trailing: isFullyPaid
              ? Chip(
                  label: Text('Receipt: ${receiptPayment.receiptNumber}'),
                  backgroundColor: Colors.green.shade100,
                )
              : null,
        ),
        if (isFullyPaid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Receipt'),
              onPressed: () {
                _showReceiptDialog(order, receiptPayment);
              },
            ),
          ),
      ],
    );
  }

  void _showReceiptDialog(LabelOrder order, LabelPayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Receipt'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Receipt Number: ${payment.receiptNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              Text('Customer: ${order.customerName}'),
              Text('Order Number: ${order.orderNumber}'),
              Text(
                  'Payment Date: ${DateFormat('yyyy-MM-dd').format(payment.paymentDate)}'),
              Text('Payment Method: ${payment.paymentType}'),
              const Divider(),
              Text('Total Amount: ${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Amount Paid: ${order.totalPaid.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('Thank you for your business!',
                  style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Print'),
            onPressed: () {
              // Implement printing functionality
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Printing not implemented yet')));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _newLabel(String newLabel, {LabelOrder? existingOrder}) async {
    final formKey = GlobalKey<FormState>();
    List<Map<String, dynamic>> paymentPairs = [
      {
        'deposit': TextEditingController(),
        'balance': TextEditingController(),
        'paymentType': 'Cash',
        'paymentDate': DateTime.now()
      }
    ];

    List<Map<String, TextEditingController>> labelPairs = [
      {
        'item': TextEditingController(),
        'label': TextEditingController(),
      }
    ];

    void calculateCharges() {
      int totalCharge = 0;
      for (var pair in labelPairs) {
        String labelText = pair['label']?.text ?? '';

        String noSpaces = labelText.replaceAll(' ', '');
        int charCount = noSpaces.length;
        totalCharge += charCount * 10;
      }

      _chargesController.text = totalCharge.toString();

      for (var paymentPair in paymentPairs) {
        if (paymentPair['deposit'].text.isNotEmpty) {
          paymentPair['balance'].text = LabelPaymentEntry.calculateBalance(
              _chargesController.text, paymentPair['deposit'].text);
        }
      }
    }

    final paymentTypes = ['Cash', 'Card', 'Mobile Money'];
    await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,
              title: Text('New Label'),
              content: SizedBox(
                width: double.infinity,
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Flexible(
                              child: TextFormField(
                                controller: _nameController,
                                decoration:
                                    const InputDecoration(labelText: "Name"),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? "Name is required"
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: TextFormField(
                                controller: _phoneNumberController,
                                decoration: const InputDecoration(
                                    labelText: "Phone Number"),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? "Phone Number is required"
                                        : null,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: "Email", border: OutlineInputBorder()),
                      ),
                      Column(
                          mainAxisSize: MainAxisSize.min,
                          children: labelPairs.asMap().entries.map((entry) {
                            var pair = entry.value;
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: TextFormField(
                                      controller: pair['item'],
                                      decoration: const InputDecoration(
                                          labelText: "Item"),
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? "Item is required"
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: TextFormField(
                                      controller: pair['label'],
                                      decoration: const InputDecoration(
                                          labelText: "Label"),
                                      validator: (value) =>
                                          value == null || value.isEmpty
                                              ? "Label is required"
                                              : null,
                                      onChanged: (value) {
                                        setState(() {
                                          calculateCharges();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList()),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (labelPairs.length > 1) {
                                      labelPairs.removeLast();
                                      calculateCharges();
                                    }
                                  });
                                },
                                icon: const Icon(Icons.remove)),
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    labelPairs.add({
                                      'item': TextEditingController(),
                                      'label': TextEditingController()
                                    });
                                  });
                                },
                                icon: const Icon(Icons.add))
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _chargesController,
                        decoration: const InputDecoration(
                            labelText: 'Charges', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter a charge' : null,
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),
                      // Payment pairs section
                      Column(
                        children: paymentPairs.asMap().entries.map((entry) {
                          int index = entry.key;
                          var pair = entry.value;
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: TextField(
                                        controller: pair['deposit'],
                                        decoration: InputDecoration(
                                          labelText: 'Deposit ${index + 1}',
                                          border: const OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          if (_chargesController
                                              .text.isNotEmpty) {
                                            pair['balance'].text =
                                                LabelPaymentEntry
                                                    .calculateBalance(
                                                        _chargesController.text,
                                                        value);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: TextField(
                                        controller: pair['balance'],
                                        decoration: InputDecoration(
                                          labelText: 'Balance ${index + 1}',
                                          border: const OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        readOnly: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Flexible(
                                      child: DropdownButtonFormField<String>(
                                        value: pair['paymentType'],
                                        decoration: const InputDecoration(
                                          labelText: 'Payment Type',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: paymentTypes.map((type) {
                                          return DropdownMenuItem(
                                            value: type,
                                            child: Text(type),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            pair['paymentType'] = value;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                          labelText: 'Payment Date',
                                          border: const OutlineInputBorder(),
                                          suffixIcon: IconButton(
                                            icon: const Icon(
                                                Icons.calendar_today),
                                            onPressed: () async {
                                              DateTime? pickedDate =
                                                  await showDatePicker(
                                                context: context,
                                                initialDate:
                                                    pair['paymentDate'],
                                                firstDate: DateTime(2000),
                                                lastDate: DateTime(2101),
                                              );
                                              if (pickedDate != null) {
                                                setState(() {
                                                  pair['paymentDate'] =
                                                      pickedDate;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                        controller: TextEditingController(
                                          text: DateFormat('yyyy-MM-dd')
                                              .format(pair['paymentDate']),
                                        ),
                                        readOnly: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (paymentPairs.length > 1) {
                                      paymentPairs.removeLast();
                                    }
                                  });
                                },
                                icon: const Icon(Icons.remove)),
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    paymentPairs.add({
                                      'deposit': TextEditingController(),
                                      'balance': TextEditingController(),
                                      'paymentType': 'Cash',
                                      'paymentDate': DateTime.now()
                                    });
                                  });
                                },
                                icon: const Icon(Icons.add)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _schedulePickUp();
                        },
                        child: const Text('Schedule Pick Up'),
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel')),
                      ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                final String orderNumber =
                                    LabelService().generateOrderNumber();

                                final List<LabelPayment> payments =
                                    paymentPairs.map((pair) {
                                  final double amount =
                                      double.parse(pair['deposit']!.text);

                                  final double totalAmount =
                                      double.parse(_chargesController.text);

                                  final LabellingPaymentStatus status =
                                      paymentPairs.indexOf(pair) == 0
                                          ? LabellingPaymentStatus.deposit
                                          : paymentPairs.indexOf(pair) ==
                                                  paymentPairs.length - 1
                                              ? LabellingPaymentStatus
                                                  .finalpayment
                                              : LabellingPaymentStatus.partial;

                                  return LabelPayment(
                                      paymentId: LabelService()
                                          .generatePaymentId(orderNumber),
                                      amount: amount,
                                      status: status,
                                      paymentDate: pair['paymentDate'],
                                      paymentType: pair['paymentType'],
                                      receiptNumber: status ==
                                              LabellingPaymentStatus
                                                  .finalpayment
                                          ? 'RCP-${LabelService().generatePaymentId(orderNumber)}'
                                          : null,
                                      recordedBy: getCurrentUser());
                                }).toList();

                                final double totalAmount =
                                    double.parse(_chargesController.text);
                                final double totalPaid = payments.fold(0.0,
                                    (sum, payment) => sum + payment.amount);

                                final LabelOrderStatus status =
                                    totalPaid >= totalAmount
                                        ? LabelOrderStatus.paid
                                        : totalPaid > 0
                                            ? LabelOrderStatus.partial
                                            : LabelOrderStatus.pending;

                                final LabelOrder newOrder = LabelOrder(
                                  orderNumber: orderNumber,
                                  createdAt: DateTime.now(),
                                  customerName: _nameController.text,
                                  customerPhoneNumber:
                                      _phoneNumberController.text,
                                  labelType: '',
                                  notes: '',
                                  item: labelPairs
                                      .map((pair) => pair['item']!.text)
                                      .join(','),
                                  label: labelPairs
                                      .map((pair) => pair['label']!.text)
                                      .join(','),
                                  totalAmount: totalAmount,
                                  payments: payments,
                                  createdBy: getCurrentUser(),
                                  status: status,
                                  fufillmentDate: currentOrder.fufillmentDate,
                                  imageUrls: currentOrder.imageUrls,
                                );

                                await LabelService().saveLabelOrder(newOrder);

                                await _loadLabelOrders();

                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Label order saved successfully')));
                                Navigator.of(context).pop();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Failed to save label order')));
                              }
                            }
                          },
                          child: const Text('Save Label Order',
                              style: TextStyle(color: Colors.green)))
                    ],
                  ),
                )
              ],
            );
          });
        });
  }

  String getCurrentUser() {
    return 'Current User_Id';
  }

  Future<void> _schedulePickUp() async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Set pick up date'),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Date: ${selectedDate.toLocal()}'.split(' ')[0]),
                  trailing: const Icon(Icons.keyboard_arrow_down),
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2025),
                    );
                    if (pickedDate != null && pickedDate != selectedDate) {
                      selectedDate = pickedDate;
                    }
                  },
                ),
                ListTile(
                  title: Text("Time: ${selectedTime.format(context)}"),
                  trailing: const Icon(Icons.keyboard_arrow_down),
                  onTap: () async {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (pickedTime != null && pickedTime != selectedTime) {
                      selectedTime = pickedTime;
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  Future _addSample() async {
    // Use local image paths in the currentOrder
    List<String> selectedImagePaths = List.from(currentOrder.imageUrls);
    if (currentOrder == null) {
      currentOrder = LabelOrder(
        orderNumber: '',
        createdAt: DateTime.now(),
        customerName: '',
        customerPhoneNumber: '',
        labelType: '',
        imageUrls: [],
        notes: '',
        item: '',
        label: '',
        totalAmount: 0.0,
        payments: [],
        status: LabelOrderStatus.pending,
        fufillmentDate: null,
        createdBy: '',
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add samples'),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Take photo option
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  // Implement camera functionality
                  final XFile? photo =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    _processPickedImage(photo);
                  }
                },
              ),

              // Gallery option
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),

              // Social media link option
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Add social media link'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddLinkDialog();
                },
              ),

              // Preview section for selected images
              SizedBox(
                height: 150,
                child: _multipleImages.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _multipleImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.memory(
                              _multipleImages[index],
                              height: 140,
                              width: 140,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      )
                    : const Center(child: Text('No images selected')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _saveSelectedImages();
                Navigator.pop(context);
              },
              child: const Text('Save All'),
            ),
          ],
        );
      },
    );
  }

// Process a single picked image
  Future<void> _processPickedImage(XFile imageFile) async {
    try {
      final File file = File(imageFile.path);
      final Uint8List bytes = await file.readAsBytes();

      final String savedPath = await _saveImageToStorage(bytes);

      setState(() {
        _multipleImages.add(bytes);
        currentOrder.imageUrls.add(savedPath);
        print("Image path added: $savedPath");
        print("Current image urls : ${currentOrder.imageUrls}");
      });
    } catch (e) {
      print("Error in _processPickedImage: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing image: $e")),
      );
    }
  }

// Pick multiple images from gallery
  Future<void> _pickMultipleImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      for (XFile pickedFile in pickedFiles) {
        await _processPickedImage(pickedFile);
      }
    }
  }

// Save an image to storage and return its path
  Future<String> _saveImageToStorage(Uint8List bytes) async {
    try {
      final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/image_$uniqueId.jpg';
      final File file = File(filePath);
      print("Saving image to: $filePath");
      await file.writeAsBytes(bytes);
      print("Image saved to: $filePath");
      return filePath;
    } catch (e) {
      print("Error saving image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving image: $e")),
      );
      return "";
    }
  }

// Save all selected images to the current order
  void _saveSelectedImages() {
    setState(() {
      currentOrder = LabelOrder(
        orderNumber: currentOrder.orderNumber,
        createdAt: currentOrder.createdAt,
        customerName: currentOrder.customerName,
        customerPhoneNumber: currentOrder.customerPhoneNumber,
        labelType: currentOrder.labelType,
        imageUrls: currentOrder.imageUrls,
        notes: currentOrder.notes,
        item: currentOrder.item,
        label: currentOrder.label,
        totalAmount: currentOrder.totalAmount,
        payments: currentOrder.payments,
        status: currentOrder.status,
        fufillmentDate: currentOrder.fufillmentDate,
        createdBy: currentOrder.createdBy,
      );
      print("saved image urls: ${currentOrder.imageUrls}");
    });
  }

// Load all images for the current order
  Future<List<Uint8List>> _loadImagesForOrder(LabelOrder order) async {
    List<Uint8List> images = [];

    try {
      for (String? imagePath in order.imageUrls) {
        if (imagePath != null && imagePath.isNotEmpty) {
          if (imagePath.startsWith('http')) {
            // Handle URLs (social media links) if needed
          } else {
            print("Loading image from: $imagePath");
            final File imageFile = File(imagePath);
            if (await imageFile.exists()) {
              final Uint8List bytes = await imageFile.readAsBytes();
              print("Image loaded, bytes length: ${bytes.length}");
              images.add(bytes);
            } else {
              print("File does not exist: $imagePath");
            }
          }
        }
      }
      print("Loaded ${images.length} images for order ${order.orderNumber}");
    } catch (e) {
      print("Error loading order images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading images: $e")),
      );
    }
    return images;
  }

// Method to open full-screen image view
  void _openFullScreenImage(
      BuildContext context, List<Uint8List> images, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Image Preview',
                style: TextStyle(color: Colors.white)),
          ),
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Center(
              child: PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(
                      images[index],
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

// Show dialog to add social media link
  void _showAddLinkDialog() {
    final TextEditingController linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Social Media Link'),
          content: TextField(
            controller: linkController,
            decoration: const InputDecoration(
              hintText: 'Enter social media image link',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (linkController.text.isNotEmpty) {
                  setState(() {
                    currentOrder.imageUrls.add(linkController.text);
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
