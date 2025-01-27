import 'package:flutter/material.dart';
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
  List<CurtainItem> curtainItems = [];
  @override
  void initState() {
    super.initState();
    _loadCurtainItems();
  }

  Future<void> _loadCurtainItems() async {
    try {
      final loadedCurtainItems = await CurtainManager.loadCurtainItems();
      setState(() {
        curtainItems = loadedCurtainItems;
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
              child: curtainItems.isEmpty
                  ? const Center(
                      child:
                          Text("No Curtain Item added yer. Add your first one"),
                    )
                  : ListView.builder(itemBuilder: (context, index) {
                      final curtainItem = curtainItems[index];
                      return GestureDetector(
                        child: buildCurtainItemCard(curtainItem),
                      );
                    }))
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}),
    );
  }

  Widget buildCurtainItemCard(CurtainItem curtainItem) {
    double totalDeposited = curtainItem.curtainPaymentEntries
        .map((entry) => double.parse(entry.deposit))
        .fold(0, (a, b) => a + b);

    double originalCharges = double.parse(curtainItem.charges);
    double remainingBalance = originalCharges - totalDeposited;
    return Card(
      child: ExpansionTile(
        title: Text(curtainItem.name),
        subtitle: Text('Phone Number: ${curtainItem.phoneNumber}'),
        children: [
          ListTile(
            title: Text(
                'Material Owner: ${curtainItem.materialOwner == true ? 'Customer Material' : 'Tailor Material'}'),
          ),
          ListTile(
            title: Text('Measurements: ${curtainItem.measurements}'),
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
                ...curtainItem.part.split(',').asMap().entries.map((entry) {
                  int index = entry.key;
                  String part = entry.value.trim();
                  String measurement =
                      curtainItem.measurement.split(',')[index].trim();
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
            title: Text('Charges: ${curtainItem.charges}'),
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
                "Payment History(${curtainItem.curtainPaymentEntries.length} entries)"),
            children: curtainItem.curtainPaymentEntries
                .map((entry) => ListTile(
                      title: Text("Deposit: ${entry.deposit}"),
                      subtitle: Text(
                          "Type: ${entry.paymentMethod}, Date: ${DateFormat('yyyy-MM-dd').format(entry.paymentDate)}"),
                    ))
                .toList(),
          ),
          ListTile(
            title: Text(
                'Pick Up Date: ${curtainItem.pickUpDate?.toIso8601String() ?? 'Not Scheduled'}'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    _sendPickUpNotification(curtainItem);
                  },
                  child: Text('Ready for pickup')),
              ElevatedButton(
                  onPressed: () {
                    _showUpdatePaymentDialog(curtainItem);
                  },
                  child: Text('Update Payment'))
            ],
          )
        ],
      ),
    );
  }

  void _sendPickUpNotification(CurtainItem clothingItem) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Pickup notification sent to ${clothingItem.name}")));
    } catch (e) {
      print('Notification error: $e');
    }
  }

  void _showUpdatePaymentDialog(CurtainItem curtainItem) async {
    final depositController = TextEditingController();
    final paymentTypeController = TextEditingController(text: "Cash");
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Update Payment for ${curtainItem.name}"),
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
                    _processPayment(curtainItem, depositController.text,
                        paymentTypeController.text);
                    Navigator.of(context).pop();
                  },
                  child: Text("Add Payment"))
            ],
          );
        });
  }

  void _processPayment(
      CurtainItem curtainItem, String depositAmount, String paymentType) async {
    CurtainpaymentEntry newPayment = CurtainpaymentEntry(
      deposit: depositAmount,
      balance: (double.parse(curtainItem.charges) -
              (curtainItem.curtainPaymentEntries
                      .fold(0, (sum, entry) => sum + int.parse(entry.deposit)) +
                  double.parse(depositAmount)))
          .toString(),
      paymentDate: DateTime.now(),
      paymentMethod: paymentType,
    );

    curtainItem.curtainPaymentEntries.add(newPayment);
    CurtainManager.saveCurtainItem(curtainItems);
    setState(() {
      _loadCurtainItems();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment of $depositAmount processed'),
    ));
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
    await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,
              title: const Text("New Curtain"),
              content: Form(
                key: formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: "Name"),
                          validator: (value) => value == null || value.isEmpty
                              ? "Name is required"
                              : null,
                        )),
                        const SizedBox(width: 10),
                        Expanded(
                            child: TextFormField(
                          controller: _phoneNumberController,
                          decoration:
                              const InputDecoration(labelText: "Phone Number"),
                          validator: (value) => value == null || value.isEmpty
                              ? "Phone Number is required"
                              : null,
                          keyboardType: TextInputType.phone,
                        )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: "Email", border: OutlineInputBorder()),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        Radio(
                            value: false,
                            groupValue: materialOwner,
                            onChanged: (value) {
                              setState(() {
                                materialOwner = value!;
                              });
                            }),
                        const Text("Own Material"),
                        const SizedBox(
                          height: 10,
                        ),
                        Column(
                          children:
                              measurementPairs.asMap().entries.map((entry) {
                            var pair = entry.value;
                            return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(children: [
                                  Expanded(
                                      child: TextField(
                                    controller: pair['part'],
                                    decoration: const InputDecoration(
                                        labelText: 'Part',
                                        border: OutlineInputBorder()),
                                    keyboardType: TextInputType.name,
                                  )),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                      child: TextField(
                                    controller: pair['measurement'],
                                    decoration: const InputDecoration(
                                        labelText: "Measurement",
                                        border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                  ))
                                ]));
                          }).toList(),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                icon: const Icon(Icons.add))
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        TextFormField(
                          maxLines: 10,
                          controller: _measurementsController,
                          decoration: const InputDecoration(
                              labelText: 'Measurements',
                              border: OutlineInputBorder()),
                          validator: (value) => value!.isEmpty
                              ? 'Please enter measurements'
                              : null,
                        ),
                        TextFormField(
                          controller: _chargesController,
                          decoration:
                              const InputDecoration(labelText: 'Charges'),
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter a charge' : null,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Column(
                          children: [
                            // Dynamic text fields going downwards

                            Column(
                              children:
                                  paymentPairs.asMap().entries.map((entry) {
                                int index = entry.key;
                                var pair = entry.value;
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: pair['deposit'],
                                            decoration: InputDecoration(
                                              labelText: 'Deposit ${index + 1}',
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              // Automatically calculate balance when deposit changes
                                              if (_chargesController
                                                  .text.isNotEmpty) {
                                                pair['balance'].text =
                                                    CurtainpaymentEntry
                                                        .calculateBalance(
                                                            _chargesController
                                                                .text,
                                                            value);
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: pair['balance'],
                                            decoration: InputDecoration(
                                              labelText: 'Balance ${index + 1}',
                                              border:
                                                  const OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            readOnly: true, // Auto-calculated
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 15,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child:
                                              DropdownButtonFormField<String>(
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
                                        Expanded(
                                          child: TextFormField(
                                            decoration: InputDecoration(
                                              labelText: 'Payment Date',
                                              border:
                                                  const OutlineInputBorder(),
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
                                );
                              }).toList(),
                            ),

                            // Add/Remove buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        if (paymentPairs.length > 1) {
                                          // Remove the last pair
                                          paymentPairs.removeLast();
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.remove)),
                                IconButton(
                                    onPressed: () {
                                      setState(() {
                                        // Add a new pair of deposit and balance controllers
                                        paymentPairs.add({
                                          'deposit': TextEditingController(),
                                          'balance': TextEditingController(),
                                          'paymentType': 'Cash',
                                          'paymentDate': DateTime.now()
                                        });
                                      });
                                    },
                                    icon: const Icon(Icons.add))
                              ],
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (paymentPairs.length > 1) {
                                      // Remove the last pair
                                      paymentPairs.removeLast();
                                    }
                                  });
                                },
                                icon: const Icon(Icons.remove)),
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    // Add a new pair of deposit and balance controllers
                                    paymentPairs.add({
                                      'deposit': TextEditingController(),
                                      'balance': TextEditingController()
                                    });
                                  });
                                },
                                icon: const Icon(Icons.add))
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () {},
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        )),
                    ElevatedButton(
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
        });
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
