import 'package:flutter/material.dart';
import 'package:gipaw_tailor/clothesentrymodel/newandrepare.dart';
import 'package:gipaw_tailor/curtainsales/curtainsmodel.dart';
import 'package:intl/intl.dart';

class Curtainsalespage extends StatefulWidget {
  const Curtainsalespage({Key? key}) : super(key: key);
  @override
  _CurtainsalespageState createState() => _CurtainsalespageState();
}

class _CurtainsalespageState extends State<Curtainsalespage> {
  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _measurementsController = TextEditingController();
  final _chargesController = TextEditingController();
  final _curtainService = CurtainService();
  List<CurtainItem> curtainItems = [];
  List<CurtainOrder> curtainOrders = [];
  @override
  void initState() {
    super.initState();
    _loadCurtainOrders();
  }

  Future<void> _loadCurtainOrders() async {
    try {
      final loadedCurtainOrders = await _curtainService.getAllCurtainOrders();
      setState(() {
        curtainOrders = loadedCurtainOrders;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error Loading Curtain Items")));

      print('Error loading curtain items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Curtain Sales"),
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

    double originalCharges = double.parse((curtainOrder.totalAmount).toStringAsFixed(2));
    double remainingBalance = originalCharges - totalDeposited;
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Measurements:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87),
                ),
                SizedBox(height: 8),
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
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                        Text(
                          measurement,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }).toList()
              ],
            ),
          ),
          ListTile(
            title: Text('Charges: ${curtainOrder.totalAmount}'),
          ),
          ListTile(
            title: Text('Deposit Paid: ${totalDeposited.toStringAsFixed(2)}'),
          ),
          ListTile(
            title: Text(
                'Remaining Balance: ${remainingBalance.toStringAsFixed(2)}'),
          ),
          ExpansionTile(
            title: Text(
                "Payment History(${curtainOrder.payments.length} entries)"),
            children: curtainOrder.payments
                .map((entry) => ListTile(
                      title: Text("Deposit: ${entry.amount}"),
                      subtitle: Text(
                          "Type: ${entry.method}, Date: ${DateFormat('yyyy-MM-dd').format(entry.paymentDate)}"),
                    ))
                .toList(),
          ),
          ListTile(
            title: Text(
                'Pick Up Date: ${curtainOrder.fulfillmentDate ?.toIso8601String() ?? 'Not Scheduled'}'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    _sendPickUpNotification(curtainOrder);
                  },
                  child: Text('Ready for pickup')),
              ElevatedButton(
                  onPressed: () {
                    _showUpdatePaymentDialog(curtainOrder);
                  },
                  child: Text('Update Payment'))
            ],
          )
        ],
      ),
    );
  }

  void _sendPickUpNotification(CurtainOrder curtainOrder) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Pickup notification sent to ${curtainOrder.customerName}")));
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
                  decoration: InputDecoration(
                      labelText: "Deposit",
                      hintText: "Enter Deposit amount",
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(
                  height: 10,
                ),
                DropdownButtonFormField<String>(
                  value: paymentTypeController.text,
                  decoration: InputDecoration(labelText: "Payment Type"),
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
                  child: Text('Cancel')),
              ElevatedButton(
                  onPressed: () {
                    _processPayment(curtainOrder, depositController.text,
                        paymentTypeController.text);
                    Navigator.of(context).pop();
                  },
                  child: Text("Add Payment"))
            ],
          );
        });
  }

  void _processPayment(
      CurtainOrder curtainOrder, String depositAmount, String paymentType) async {
    CurtainPayment newPayment = CurtainPayment(
      amount: double.parse(depositAmount),
      balance: (double.parse((curtainOrder.totalAmount).toStringAsFixed(2)) -
              (curtainOrder.payments
                      .fold(0, (sum, entry) => sum + int.parse((entry.amount).toStringAsFixed(2))) +
                  double.parse(depositAmount)))
          .toString(),
      timestamp: DateTime.now(),
      method: paymentType,
    );

    curtainOrder.payments.add(newPayment);
    CurtainManager.saveCurtainItem(curtainItems);
    setState(() {
      _loadCurtainOrders();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment of $depositAmount processed'),
    ));
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
                    _newCurtain('New Curtain');
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

  void _newCurtain(String newCurtain) async {
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

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,
              title: const Text("New Curtain"),
              content: Container(
                width: double.infinity,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
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
                      Container(
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
                      Container(
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
                            border: OutlineInputBorder(),
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
                                    icon: Icon(Icons.attach_file))
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
                      Container(
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
                Container(
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
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              // Save logic here
                              List<CurtainpaymentEntry> payments = paymentPairs
                                  .map((pair) => CurtainpaymentEntry(
                                      deposit: pair['deposit']!.text,
                                      balance: pair['balance']!.text,
                                      paymentDate: pair['paymentDate'],
                                      paymentMethod: pair['paymentType']))
                                  .toList();
                              CurtainItem newItem = CurtainItem(
                                  name: _nameController.text,
                                  phoneNumber: _phoneNumberController.text,
                                  materialOwner:
                                      materialOwner ? 'true' : 'false',
                                  notes: _measurementsController.text,
                                  part: measurementPairs
                                      .map((pair) => pair['part']!.text)
                                      .join(','),
                                  measurement: measurementPairs
                                      .map((pair) => pair['measurement']!.text)
                                      .join(','),
                                  curtainType: curtainTypes.first,
                                  charges: _chargesController.text,
                                  orderDate: DateTime.now(),
                                  curtainPaymentEntries: payments);
                              setState(() {
                                curtainItems.add(newItem);
                              });

                              String curtainItemName =
                                  ClothingItemIdentifier.generateIdentifier(
                                      _nameController.text,
                                      _phoneNumberController.text);
                              CurtainManager.saveCurtainItem(curtainItems);
                              Navigator.of(context).pop();
                            }
                            setState(() {
                              _loadCurtainOrders();
                            });
                          },
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.green),
                          )),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addSample() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add sample'),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Take a photo'),
                IconButton(onPressed: () {}, icon: const Icon(Icons.photo))
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      )),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.green),
                      ))
                ],
              )
            ],
          );
        });
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
                      onPressed: () {},
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.green),
                      ))
                ],
              )
            ],
          );
        });
  }
}
