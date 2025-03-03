import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gipaw_tailor/clothesentrymodel/newandrepare.dart';
import 'package:gipaw_tailor/curtainsales/curtainsmodel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class Curtainsalespage extends StatefulWidget {
  const Curtainsalespage({super.key});
  @override
  _CurtainsalespageState createState() => _CurtainsalespageState();
}

class _CurtainsalespageState extends State<Curtainsalespage> {
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _measurementsController = TextEditingController();
  final _chargesController = TextEditingController();
  final _curtainService = CurtainService();

  List<CurtainOrder> curtainOrders = [];
  CurtainOrder currentOrder = CurtainOrder(
    orderNumber: '',
    createdAt: DateTime.now(),
    customerName: '',
    phoneNumber: '',
    materialOwner: '',
    curtainType: '',
    imageUrls: [],
    notes: '',
    part: '',
    measurement: '',
    totalAmount: 0.0,
    payments: [],
    status: CurtainOrderStatus.pending,
    fulfillmentDate: null,
    createdBy: '',
  );

  Uint8List? _imageBytes;

  List<Uint8List> _multipleImages = [];
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _loadCurtainOrders();
  }

  Future _loadCurtainOrders() async {
    try {
      final loadedCurtainOrders = await _curtainService.getAllCurtainOrders();
      setState(() {
        curtainOrders = loadedCurtainOrders;
      });

      // Add debug print
      print('Loaded ${curtainOrders.length} orders');
    } catch (e) {
      print('Error loading curtain items: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error Loading Curtain's Items")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Curtain Sales"),
      ),
      body: Column(
        children: [
          Expanded(
              child: curtainOrders.isEmpty
                  ? const Center(
                      child:
                          Text("No Curtain Item added yer. Add your first one"),
                    )
                  : ListView.builder(
                      itemCount: curtainOrders.length,
                      itemBuilder: (context, index) {
                        final curtainOrder = curtainOrders[index];
                        return GestureDetector(
                          child: buildCurtainItemCard(curtainOrder),
                        );
                      }))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            _newOrRepair();
          },
          tooltip: "New Curtain",
          child: const Icon(Icons.add)),
    );
  }

  Widget buildCurtainItemCard(CurtainOrder curtainOrder) {
    double totalDeposited = curtainOrder.payments
        .map((entry) => double.parse((entry.amount).toStringAsFixed(2)))
        .fold(0, (a, b) => a + b);

    double originalCharges =
        double.parse((curtainOrder.totalAmount).toStringAsFixed(2));
    double remainingBalance = originalCharges - totalDeposited;

    List<Uint8List> orderImages = curtainOrder.imageUrls.map((img) {
      if (img != null && img.startsWith("/")) {
        // It's a file path, load it as a file
        File file = File(img!);
        if (file.existsSync()) {
          return file.readAsBytesSync();
        } else {
          return Uint8List(0); // Return an empty image placeholder
        }
      } else {
        // It's a base64 string, decode it
        return base64Decode(img!);
      }
    }).toList();

    return Card(
      child: ExpansionTile(
        title: Text(curtainOrder.customerName),
        subtitle: Text('Phone Number: ${curtainOrder.phoneNumber}'),
        children: [
          ListTile(
            title: Text(
                'Material Owner: ${curtainOrder.materialOwner == true ? 'Customer Material' : 'Tailor Material'}'),
          ),
          ListTile(
            title: Text('Notes: ${curtainOrder.notes}'),
          ),
          ListTile(
            title: Text("Curtain Type : ${curtainOrder.curtainType}"),
          ),
          ElevatedButton(
              onPressed: () async {
                final images = await _loadImagesForOrder(curtainOrder);
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
                          // Open full-screen image view
                          _openFullScreenImage(context, orderImages, index);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Image.memory(orderImages[index]),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Measurements:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87),
                ),
                const SizedBox(height: 8),
                ...curtainOrder.part.split(',').asMap().entries.map((entry) {
                  int index = entry.key;
                  String part = entry.value.trim();
                  String measurement =
                      curtainOrder.measurement.split(',')[index].trim();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Text(
                          '$part: ',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                        Text(
                          measurement,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                })
              ],
            ),
          ),
          ListTile(
            title: Text('Charges: ${curtainOrder.totalAmount}'),
          ),
          ListTile(
            title: Text('Deposit Paid: ${totalDeposited.toStringAsFixed(2)}'),
          ),
          _buildBalanceInfoCurtains(curtainOrder),
          ExpansionTile(
            title: Text(
                "Payment History(${curtainOrder.payments.length} entries)"),
            children: curtainOrder.payments
                .map((entry) => ListTile(
                      title: Text("Deposit: ${entry.amount}"),
                      subtitle: Text(
                          "Type: ${entry.method}, Date: ${DateFormat('yyyy-MM-dd').format(entry.timestamp)}"),
                    ))
                .toList(),
          ),
          ListTile(
            title: Text(
                'Pick Up Date: ${curtainOrder.fulfillmentDate?.toIso8601String() ?? 'Not Scheduled'}'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    _sendPickUpNotification(curtainOrder);
                  },
                  child: const Text('Ready for pickup')),
              ElevatedButton(
                  onPressed: () {
                    _showUpdatePaymentDialog(curtainOrder);
                  },
                  child: const Text('Update Payment'))
            ],
          )
        ],
      ),
    );
  }

  void _sendPickUpNotification(CurtainOrder curtainOrder) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Pickup notification sent to ${curtainOrder.customerName}")));
    } catch (e) {
      print('Notification error: $e');
    }
  }

  void _showUpdatePaymentDialog(CurtainOrder curtainOrder) async {
    final depositController = TextEditingController();
    final paymentTypeController = TextEditingController(text: "Cash");
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Update Payment for ${curtainOrder.customerName}"),
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
                    _processPayment(curtainOrder, depositController.text,
                        paymentTypeController.text);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Add Payment"))
            ],
          );
        });
  }

  void _processPayment(CurtainOrder curtainOrder, String depositAmount,
      String paymentType) async {
    try {
      final double amount = double.parse(depositAmount);

      final double newTotalPaid = curtainOrder.totalPaid + amount;

      final CurtainPaymentStatus paymentStatus = _determinePaymentStatus(
          totalAmount: curtainOrder.totalAmount,
          currentlyPaid: curtainOrder.totalPaid,
          newPaymentAmount: amount);

      final String paymentId =
          _curtainService.generatePaymentsId(curtainOrder.orderNumber);
      final String? receiptNumber =
          paymentStatus == CurtainPaymentStatus.finalpayment
              ? 'RCP-$paymentId'
              : null;

      final CurtainPayment newPayment = CurtainPayment(
          amount: amount,
          timestamp: DateTime.now(),
          method: paymentType,
          paymentId: paymentId,
          status: paymentStatus,
          recordedBy: curtainOrder.createdBy,
          receiptNumber: receiptNumber);
      final updatePayments = [...curtainOrder.payments, newPayment];

      final CurtainOrderStatus newStatus = _determineOrderStatus(
          totalAmount: curtainOrder.totalAmount, totalPaid: newTotalPaid);

      final updateOrder = CurtainOrder(
          orderNumber: curtainOrder.orderNumber,
          createdAt: curtainOrder.createdAt,
          customerName: curtainOrder.customerName,
          phoneNumber: curtainOrder.phoneNumber,
          materialOwner: curtainOrder.materialOwner,
          curtainType: curtainOrder.curtainType,
          notes: curtainOrder.notes,
          part: curtainOrder.part,
          measurement: curtainOrder.measurement,
          totalAmount: curtainOrder.totalAmount,
          payments: updatePayments,
          createdBy: curtainOrder.createdBy,
          fulfillmentDate: curtainOrder.fulfillmentDate);
      await _curtainService.saveCurtainOrder(updateOrder);
      setState(() {
        _loadCurtainOrders();
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment of $depositAmount processed succesffully')));
    } catch (e) {
      print("Error Processing payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error Processing payment")));
    }
  }

  Widget _buildBalanceInfoCurtains(CurtainOrder order) {
    final double remainingBalance = order.remainingBalance;
    final bool isFullyPaid = order.isFullyPaid;

    // Find the last payment that has a receipt number (if any)
    final receiptPayment = order.payments.lastWhere(
        (payment) => payment.receiptNumber != null,
        orElse: () => CurtainPayment(
            amount: 0,
            timestamp: DateTime.now(),
            method: '',
            paymentId: '',
            status: CurtainPaymentStatus.partial,
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

  void _showReceiptDialog(CurtainOrder order, CurtainPayment payment) {
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
                  'Payment Date: ${DateFormat('yyyy-MM-dd').format(payment.timestamp)}'),
              Text('Payment Method: ${payment.method}'),
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

  CurtainPaymentStatus _determinePaymentStatus({
    required double totalAmount,
    required double currentlyPaid,
    required double newPaymentAmount,
  }) {
    final double totalAfterPayment = currentlyPaid + newPaymentAmount;

    if (currentlyPaid == 0) {
      return CurtainPaymentStatus.deposit;
    } else if (totalAfterPayment >= totalAmount) {
      return CurtainPaymentStatus.finalpayment;
    } else {
      return CurtainPaymentStatus.partial;
    }
  }

  CurtainOrderStatus _determineOrderStatus({
    required double totalAmount,
    required double totalPaid,
  }) {
    if (totalPaid >= totalAmount) {
      return CurtainOrderStatus.paid;
    } else if (totalPaid > 0) {
      return CurtainOrderStatus.partial;
    } else {
      return CurtainOrderStatus.pending;
    }
  }

  Future<void> _newOrRepair() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('New or Repair'),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('New'),
                  onTap: () {
                    Navigator.pop(context);
                    _newCurtain('New Curtain', existingOrder: currentOrder);
                  },
                ),
                ListTile(
                  title: const Text('Repair'),
                  onTap: () {
                    Navigator.pop(context);
                    _addSample();
                  },
                )
              ],
            ),
          );
        });
  }

  void _newCurtain(String newCurtain, {CurtainOrder? existingOrder}) async {
    final formKey = GlobalKey<FormState>();
    List<Map<String, dynamic>> paymentPairs = [
      {
        'deposit': TextEditingController(),
        'balance': TextEditingController(),
        'paymentType': "Cash",
        'paymentDate': DateTime.now()
      }
    ];
    List<Map<String, TextEditingController>> measurementPairs = [
      {
        'part': TextEditingController(),
        'measurement': TextEditingController(),
      }
    ];

    bool materialOwner = false;
    final paymentTypes = ["Cash", "Card", "Bank Transfer", "Mpesa"];
    final curtainTypes = ["Rings", "Hooks", "Other"];

    CurtainOrder currentOrder = existingOrder ??
        CurtainOrder(
          imageUrls:
              _multipleImages.map((image) => base64Encode(image)).toList(),
          orderNumber: '',
          createdAt: DateTime.now(),
          customerName: '',
          phoneNumber: '',
          materialOwner: '',
          curtainType: curtainTypes.first,
          notes: '',
          part: '',
          measurement: '',
          totalAmount: 0.0,
          payments: [],
          createdBy: getCurrentUser(),
          status: CurtainOrderStatus.pending,
        );

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,
              title: const Text("New Curtain"),
              content: SizedBox(
                width: double.infinity,
                child: Form(
                  key: formKey,
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
                      const SizedBox(height: 5),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              children: [
                                Radio(
                                  value: true,
                                  groupValue: materialOwner,
                                  onChanged: (value) {
                                    setState(() {
                                      materialOwner = value!;
                                    });
                                  },
                                ),
                                const Text("Customer Material"),
                              ],
                            ),
                            Row(
                              children: [
                                Radio(
                                    value: false,
                                    groupValue: materialOwner,
                                    onChanged: (value) {
                                      setState(() {
                                        materialOwner = value!;
                                      });
                                    }),
                                const Text("Own Material"),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Flexible(
                            child: DropdownButtonFormField<String>(
                              value: curtainTypes.first,
                              items: curtainTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  // Handle the value change
                                });
                              },
                            ),
                          )
                        ],
                      ),

                      // Measurement pairs section
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: measurementPairs.asMap().entries.map((entry) {
                          var pair = entry.value;
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Flexible(
                                  child: TextField(
                                    controller: pair['part'],
                                    decoration: const InputDecoration(
                                        labelText: 'Part',
                                        border: OutlineInputBorder()),
                                    keyboardType: TextInputType.name,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: TextField(
                                    controller: pair['measurement'],
                                    decoration: const InputDecoration(
                                        labelText: "Measurement",
                                        border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                  ),
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
                                    if (measurementPairs.length > 1) {
                                      measurementPairs.removeLast();
                                    }
                                  });
                                },
                                icon: const Icon(Icons.remove)),
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    measurementPairs.add({
                                      'part': TextEditingController(),
                                      'measurement': TextEditingController()
                                    });
                                  });
                                },
                                icon: const Icon(Icons.add)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        maxLines: 3,
                        controller: _measurementsController,
                        decoration: InputDecoration(
                            labelText: 'Additional Notes',
                            border: const OutlineInputBorder(),
                            suffixIcon: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      _addSample();
                                    },
                                    icon: const Icon(Icons.photo)),
                                IconButton(
                                    onPressed: () {
                                      _addSample();
                                    },
                                    icon: const Icon(Icons.camera_alt)),
                                IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.attach_file))
                              ],
                            )),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _chargesController,
                        decoration: const InputDecoration(
                            labelText: 'Charges', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter a charge' : null,
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
                                                CurtainpaymentEntry
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
                      const SizedBox(height: 10),
                      ElevatedButton(
                          onPressed: () {
                            _schedulePickUp();
                          },
                          child: const Text("Pick Up date"))
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
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          )),
                      ElevatedButton(
                          onPressed: () async {
                            // Made async to handle Future
                            if (formKey.currentState!.validate()) {
                              try {
                                // Generate order number
                                final String orderNumber =
                                    _curtainService.generateOrderNumber();

                                // Create payments list with proper status tracking
                                final List<CurtainPayment> payments =
                                    paymentPairs.map((pair) {
                                  final double amount =
                                      double.parse(pair['deposit']!.text);
                                  final double totalAmount =
                                      double.parse(_chargesController.text);

                                  // Determine payment status based on order in sequence
                                  final CurtainPaymentStatus status =
                                      paymentPairs.indexOf(pair) == 0
                                          ? CurtainPaymentStatus.deposit
                                          : paymentPairs.indexOf(pair) ==
                                                  paymentPairs.length - 1
                                              ? CurtainPaymentStatus
                                                  .finalpayment
                                              : CurtainPaymentStatus.partial;

                                  return CurtainPayment(
                                    paymentId: _curtainService
                                        .generatePaymentsId(orderNumber),
                                    timestamp: pair['paymentDate'],
                                    amount: amount,
                                    method: pair['paymentType'],
                                    status: status,
                                    receiptNumber: status ==
                                            CurtainPaymentStatus.finalpayment
                                        ? 'RCP-${_curtainService.generatePaymentsId(orderNumber)}'
                                        : null,
                                    recordedBy:
                                        getCurrentUser(), // Assuming you have a method to get current user
                                  );
                                }).toList();

                                // Calculate total amount from charges
                                final double totalAmount =
                                    double.parse(_chargesController.text);

                                // Calculate total paid amount
                                final double totalPaid = payments.fold(0.0,
                                    (sum, payment) => sum + payment.amount);

                                // Determine initial order status
                                final CurtainOrderStatus status =
                                    totalPaid >= totalAmount
                                        ? CurtainOrderStatus.paid
                                        : totalPaid > 0
                                            ? CurtainOrderStatus.partial
                                            : CurtainOrderStatus.pending;

                                // Create new curtain order
                                final CurtainOrder newOrder = CurtainOrder(
                                    orderNumber: orderNumber,
                                    createdAt: DateTime.now(),
                                    customerName: _nameController.text,
                                    phoneNumber: _phoneNumberController.text,
                                    materialOwner:
                                        materialOwner ? 'Customer' : 'Shop',
                                    curtainType: curtainTypes.first,
                                    notes: _measurementsController.text,
                                    part: measurementPairs
                                        .map((pair) => pair['part']!.text)
                                        .join(','),
                                    measurement: measurementPairs
                                        .map(
                                            (pair) => pair['measurement']!.text)
                                        .join(','),
                                    totalAmount: totalAmount,
                                    payments: payments,
                                    createdBy:
                                        getCurrentUser(), // Assuming you have a method to get current user
                                    status: status,
                                    imageUrls: currentOrder.imageUrls,
                                    fulfillmentDate:
                                        currentOrder.fulfillmentDate);

                                // Save the order using the service
                                await _curtainService
                                    .saveCurtainOrder(newOrder);

                                // Refresh the orders list
                                await _loadCurtainOrders();

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Curtain order saved successfully')),
                                );

                                // Close the form
                                Navigator.of(context).pop();
                              } catch (e) {
                                print('Error saving curtain order: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Error saving curtain order')),
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.green),
                          )),
                    ],
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  String getCurrentUser() {
    return 'current_user_id';
  }

  Future _addSample() async {
    // Use local image paths in the currentOrder
    List<String> selectedImagePaths = List.from(currentOrder.imageUrls);
    if (currentOrder == null) {
      currentOrder = CurtainOrder(
        orderNumber: '',
        createdAt: DateTime.now(),
        customerName: '',
        phoneNumber: '',
        materialOwner: '',
        curtainType: '',
        imageUrls: [],
        notes: '',
        part: '',
        measurement: '',
        totalAmount: 0.0,
        payments: [],
        status: CurtainOrderStatus.pending,
        fulfillmentDate: null,
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
      currentOrder = CurtainOrder(
        orderNumber: currentOrder.orderNumber,
        createdAt: currentOrder.createdAt,
        customerName: currentOrder.customerName,
        phoneNumber: currentOrder.phoneNumber,
        materialOwner: currentOrder.materialOwner,
        curtainType: currentOrder.curtainType,
        imageUrls: currentOrder.imageUrls,
        notes: currentOrder.notes,
        part: currentOrder.part,
        measurement: currentOrder.measurement,
        totalAmount: currentOrder.totalAmount,
        payments: currentOrder.payments,
        status: currentOrder.status,
        fulfillmentDate: currentOrder.fulfillmentDate,
        createdBy: currentOrder.createdBy,
      );
      print("saved image urls: ${currentOrder.imageUrls}");
    });
  }

// Load all images for the current order
  Future<List<Uint8List>> _loadImagesForOrder(CurtainOrder order) async {
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

// Helper function to show loading dialog
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

// Helper function to upload image to storage
  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      // Generate a unique filename
      String fileName = 'sample_${DateTime.now().millisecondsSinceEpoch}';

      // Reference to storage location
      Reference storageRef =
          FirebaseStorage.instance.ref().child('samples/$fileName');

      // Upload file
      await storageRef.putFile(imageFile);

      // Get download URL
      String downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
      return null;
    }
  }

// Helper function to show confirmation dialog with multiple images
  void _showImagesConfirmationDialog(List<String> imageUrls) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sample Images'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Container(
                        width: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(imageUrls[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('Would you like to add more samples or save these?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _addSample(); // Go back to add more
              },
              child: const Text('Add More'),
            ),
            TextButton(
              onPressed: () {
                // Save the image URLs to your CurtainOrder
                setState(() {
                  currentOrder = CurtainOrder(
                    // Copy all existing fields
                    orderNumber: currentOrder.orderNumber,
                    createdAt: currentOrder.createdAt,
                    customerName: currentOrder.customerName,
                    phoneNumber: currentOrder.phoneNumber,
                    materialOwner: currentOrder.materialOwner,
                    curtainType: currentOrder.curtainType,
                    imageUrls: imageUrls, // Update with new list
                    notes: currentOrder.notes,
                    part: currentOrder.part,
                    measurement: currentOrder.measurement,
                    totalAmount: currentOrder.totalAmount,
                    payments: currentOrder.payments,
                    status: currentOrder.status,
                    fulfillmentDate: currentOrder.fulfillmentDate,
                    createdBy: currentOrder.createdBy,
                  );
                });
                Navigator.pop(context);
              },
              child:
                  const Text('Save All', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

// Helper function to show dialog for entering a social media link
  void _showLinkInputDialog(List<String> currentImageUrls) {
    String? link;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter social media link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Paste link here',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  link = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _addSample(); // Go back to main add sample dialog
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                if (link != null && link!.isNotEmpty) {
                  // Validate the link (you might want to add more validation)
                  if (Uri.tryParse(link!)?.hasAbsolutePath ?? false) {
                    Navigator.pop(context);

                    // Add the link to current list of image URLs
                    List<String> updatedUrls = List.from(currentImageUrls);
                    updatedUrls.add(link!);

                    // Show confirmation dialog with all images/links
                    _showImagesConfirmationDialog(updatedUrls);
                  } else {
                    // Show error for invalid link
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid URL')),
                    );
                  }
                }
              },
              child: const Text('Add', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
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
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != selectedDate) {
                      selectedDate = pickedDate;
                    }
                  },
                ),
                ListTile(
                  title: Text('Time: ${selectedTime.format(context)}'),
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
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      )),
                  TextButton(
                      onPressed: () {
                        final DateTime fulfillmentDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        Navigator.of(context).pop(fulfillmentDateTime);
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.green),
                      ))
                ],
              )
            ],
          );
        }).then((value) {
      if (value != null) {
        setState(() {
          currentOrder.fulfillmentDate = value;
        });
      }
    });
  }
}
