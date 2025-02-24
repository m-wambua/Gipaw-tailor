import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gipaw_tailor/clothesentrymodel/clothingandrepairsales.dart';
import 'package:gipaw_tailor/clothesentrymodel/newandrepare.dart';
import 'package:gipaw_tailor/contacts/contactspage.dart';
import 'package:gipaw_tailor/curtainsales/curtainorderform.dart';
import 'package:gipaw_tailor/curtainsales/curtainsalespage.dart';
import 'package:gipaw_tailor/curtainsales/curtainsmodel.dart';
import 'package:gipaw_tailor/paymentmethod/mpesa/mpesapage.dart';
import 'package:gipaw_tailor/receipts/receipts.dart';
import 'package:gipaw_tailor/receipts/receiptservice.dart';
import 'package:gipaw_tailor/receipts/salesreceiptpage.dart';
import 'package:gipaw_tailor/remindersystem/reminderclass.dart';
import 'package:gipaw_tailor/remindersystem/reminderpage.dart';
import 'package:gipaw_tailor/signinpage/admindash.dart';
import 'package:gipaw_tailor/signinpage/authorization.dart';
import 'package:gipaw_tailor/signinpage/protectedroutes.dart';
import 'package:gipaw_tailor/signinpage/signinpage.dart';
import 'package:gipaw_tailor/signinpage/signuppage.dart';
import 'package:gipaw_tailor/signinpage/users.dart';
import 'package:gipaw_tailor/uniforms/sales/salesitems.dart';
import 'package:gipaw_tailor/uniforms/sales/salesviewer.dart';
import 'package:gipaw_tailor/uniforms/stock/stocktable.dart';
import 'package:gipaw_tailor/uniforms/stockmanager.dart';
import 'package:gipaw_tailor/uniforms/uniforms_data.dart';
import 'package:intl/intl.dart';
import 'package:gipaw_tailor/receipts/receipts.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final int _counter = 0;
  final _namecontroller = TextEditingController();
  final _phoneNumbercontroller = TextEditingController();
  final _measurementsController = TextEditingController();
  final _chargesController = TextEditingController();
  final _commentsController = TextEditingController();
  String stockPath = 'lib/uniforms/stock/stock.json';
  final stockManager = StockManager('lib/uniforms/stock/stock.json');
  List<Map<String, dynamic>> entries = [];
  List<ClothingOrder> clothingOrder = [];

  final List<UserRole> allowedRoles = [];

  final double sidebarWidth = 250.0;

  
  List<CurtainItem> curtainItems = [];

  @override
  void initState() {
    super.initState();
    _loadClothingItems();
    _loadCurtainItems();
  }

  Future<void> _loadClothingItems() async {
    try {
      final loadedClothingItems = await ClothingService().getAllClothingOrders();
      setState(() {
        clothingOrder = loadedClothingItems;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading clothing items')));
    }
  }

  Future<void> _loadCurtainItems() async {
    try {
      final loadedCurtainItems = await CurtainManager.loadCurtainItems();
      setState(() {
        curtainItems = loadedCurtainItems;
        print(curtainItems);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error Loading Curtain Items")));

      print('Error loading curtain items: $e');
    }
  }

  @override
  void _newPiece(String newClothing) async {
    final formKey = GlobalKey<FormState>();
    List<Map<String, dynamic>> paymentPairs = [
      {
        'deposit': TextEditingController(),
        'balance': TextEditingController(),
        'paymentType': 'Cash',
        'paymentDate': DateTime.now()
      }
    ];
    List<Map<String, TextEditingController>> measurementPairs = [
      {'part': TextEditingController(), 'measurement': TextEditingController()}
    ];
    bool materialOwner = false;
    final paymentTypes = ['Cash', 'Card', 'Bank Transfer', 'Mpesa'];
    TextEditingController emailController=TextEditingController();

    await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                scrollable: true,
                title: const Text('Create New Clothing Item'),
                content: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: TextFormField(
                              controller: _namecontroller,
                              decoration:
                                  const InputDecoration(labelText: 'Name'),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please enter a name'
                                      : null,
                            )),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                                child: TextFormField(
                              controller: _phoneNumbercontroller,
                              decoration: const InputDecoration(
                                  labelText: 'Phone number'),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Please enter a phone number'
                                      : null,
                              keyboardType: TextInputType.phone,
                            ))
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: "email", border: OutlineInputBorder()),
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
                          ],
                        ),
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
                        const SizedBox(
                          height: 10,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              _addSample();
                            },
                            child: const Text('Add Sample')),
                        const SizedBox(
                          height: 10,
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
                                                    PaymentEntry
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
                        ElevatedButton(
                            onPressed: () {
                              _schedulePickUp();
                            },
                            child: const Text('Pick up date'))
                      ],
                    )),
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
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {

                              try{
                                final String orderNumber=ClothingService().generateOrderNumber();
                                final List<ClothingPayment> payments=paymentPairs.map((pair){
                                  final double amount=double.parse(pair['deposit']!.text);
                                  final double totalAmount=double.parse(_chargesController.text);
                                  final ClothingPaymentStatus status=paymentPairs.indexOf(pair)==0 ? ClothingPaymentStatus.deposit : paymentPairs.length - 1 == paymentPairs.indexOf(pair) ? ClothingPaymentStatus.finalpayment : ClothingPaymentStatus.partial;

                                  return ClothingPayment(paymentId: ClothingService().generatePaymentId(orderNumber), timestamp: pair['paymentDate'],
                                   amount: amount,
                                    method: pair['paymentType'],
                                     status: status,
                                      receiptNumber: status== ClothingPaymentStatus.finalpayment ? 'RCP-${ClothingService().generatePaymentId(orderNumber)}': null,
                                       recorderdBy: getCurrentUser());
                                  
                                }).toList();
                                final double totalAmount=double.parse(_chargesController.text);
                                final double totalPaid=payments.fold(0.0,(sum,payment)=>sum + payment.amount);

                                final ClothesOrderStatus status=
                                totalPaid>= totalAmount ? ClothesOrderStatus.paid :totalPaid>0 ? ClothesOrderStatus.partial : ClothesOrderStatus.pending;  

                                final ClothingOrder order=ClothingOrder(
                                  orderName: orderNumber,
                                 customerName: _namecontroller.text,
                                 createdAt: DateTime.now(),
                                  phoneNumber: _phoneNumbercontroller.text, 
                                  email: emailController.text,
                                  materialOwner: materialOwner ? 'Customer' : 'Shop',
                                   
                                    part: measurementPairs.map((pair)=>pair['part']!.text).join(','),
                                     measurement: measurementPairs.map((pair)=>pair['measurement']!.text).join(','),
                                    notes: _commentsController.text, 
                                    totalAmount: double.parse(_chargesController.text), payments: payments, status: status,
                                     createdBy: getCurrentUser(),
                                     imageUrl: '',
                                      fulfillmentDate: DateTime.now().add(const Duration(days: 7)),
                                      
                                    
                                     );
                                     await ClothingService().saveClothingOrder(order);

                                     await _loadClothingItems();

                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clothing Order Saved successfully')));
                                      Navigator.pop(context);
                              } catch(e){
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error Saving Clothing Order')));
                              }
                            }},
                          child: const Text(
                            'Save',
                            style: TextStyle(color: Colors.green),
                          ))
                    ],
                  )
                ],
              );
            },
          );
        });
  }
    String getCurrentUser() {
    return 'current_user_id';
  }

  void _repair(String newClothing) async {
    List<Map<String, TextEditingController>> paymentPairs = [
      {'deposit': TextEditingController(), 'balance': TextEditingController()}
    ];
    List<Map<String, TextEditingController>> measurementPairs = [
      {'part': TextEditingController(), 'measurement': TextEditingController()}
    ];

    await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Create New Clothing Item'),
              content: Form(
                  child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: TextFormField(
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter a name' : null,
                      )),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                          child: TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Phone number'),
                        validator: (value) => value!.isEmpty
                            ? 'Please enter a phone number'
                            : null,
                      ))
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: "email", border: OutlineInputBorder()),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Column(
                    children: measurementPairs.asMap().entries.map((entry) {
                      int index = entry.key;
                      var pair = entry.value;
                      return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
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
                                    labelText: 'Measurement',
                                    border: OutlineInputBorder()),
                                keyboardType: TextInputType.number,
                              ))
                            ],
                          ));
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
                  TextFormField(
                    maxLines: 5,
                    decoration: const InputDecoration(
                        labelText: 'comments', border: OutlineInputBorder()),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter comment' : null,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        _addSample();
                      },
                      child: const Text('Add Sample')),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Charges'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a charge' : null,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Column(
                    children: [
                      // Dynamic text fields going downwards
                      Column(
                        children: paymentPairs.asMap().entries.map((entry) {
                          int index = entry.key;
                          var pair = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: pair['deposit'],
                                    decoration: InputDecoration(
                                      labelText: 'Deposit ${index + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: pair['balance'],
                                    decoration: InputDecoration(
                                      labelText: 'Balance ${index + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
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
                                    'balance': TextEditingController()
                                  });
                                });
                              },
                              icon: const Icon(Icons.add))
                        ],
                      )
                    ],
                  ),
                  ElevatedButton(
                      onPressed: () {
                        _promptPayment();
                      },
                      child: const Text('Prompt Payment')),
                  const SizedBox(
                    height: 10,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        _schedulePickUp();
                      },
                      child: const Text('Pick up date'))
                ],
              )),
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

  Future<void> _newOrRepare() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sell Items'),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('New Clothing'),
                  onTap: () {
                    Navigator.pop(context);
                    _newPiece("New Clothing");
                  },
                ),
                ListTile(
                  title: const Text('Repair'),
                  onTap: () {
                    Navigator.pop(context);
                    _repair("Repair");
                  },
                ),
                ListTile(
                  title: const Text('Curtains'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Curtainsalespage()));
                  },
                ),
                ListTile(
                  title: const Text('Uniforms'),
                  onTap: () {
                    Navigator.pop(context);
                    _uniformSales();
                  },
                )
              ],
            ),
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

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.

        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Welcome to Gipaw Tailor"),
        actions: const [
/*
          IconButton(onPressed: , icon: Icon(Icons.search)),
          IconButton(onPressed: , icon: Icon(Icons.person))
          */
        ],
      ),
      body: Row(
        children: [
          Container(
            width: sidebarWidth,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Expanded(
                    child: ListView(padding: EdgeInsets.zero, children: [
                  ProtectedNavigationButton(
                      text: "Sell Uniform",
                      allowedRoles: [
                        UserRole.admin,
                        UserRole.manager,
                        UserRole.user
                      ],
                      onPressed: _uniformSales),
                  ProtectedNavigationButton(
                      text: 'Customer Receipts',
                      allowedRoles: [
                        UserRole.manager,
                        UserRole.user,
                        UserRole.admin
                      ],
                      onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ReceiptPage()),
                          )),
                  ProtectedNavigationButton(
                      text: "Sell Curtains",
                      allowedRoles: [
                        UserRole.admin,
                        UserRole.manager,
                        UserRole.user
                      ],
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Curtainsalespage()));
                      }),
                  ProtectedNavigationButton(
                      text: "Sell New Clothes",
                      allowedRoles: [
                        UserRole.admin,
                        UserRole.manager,
                        UserRole.user
                      ],
                      onPressed: () => _newOrRepare()),
                  ProtectedNavigationButton(
                      text: "View Stock",
                      allowedRoles: [UserRole.admin, UserRole.manager],
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => StockViewWrapper(
                                    stockFilePath: stockPath)));
                      }),
                  ProtectedNavigationButton(
                      text: "Sales",
                      allowedRoles: [UserRole.admin, UserRole.manager],
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SalesViewWrapper(
                                    salesFilePath:
                                        'lib/uniforms/sales/sales.json')));
                      }),
                  ProtectedNavigationButton(
                      text: "Reminders",
                      allowedRoles: [UserRole.admin, UserRole.manager],
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ReminderPage()));
                      }),
                  ProtectedNavigationButton(
                      text: "Contacts",
                      allowedRoles: [UserRole.admin, UserRole.manager],
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ContactsPage()));
                      }),
                  ProtectedNavigationButton(
                      text: "Sales Summary",
                      allowedRoles: [UserRole.admin, UserRole.manager],
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SalesSummary()));
                      }),
                  ProtectedNavigationButton(
                      text: "Sign Up!",
                      allowedRoles: [
                        UserRole.admin,
                        UserRole.manager,
                        UserRole.user
                      ],
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpPage()));
                      }),
                  ProtectedNavigationButton(
                      text: "Sign In",
                      allowedRoles: [
                        UserRole.admin,
                        UserRole.manager,
                        UserRole.user
                      ],
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignInPage()))),
                  ProtectedNavigationButton(
                      text: "Admin DashBoard",
                      allowedRoles: [UserRole.admin],
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AdminDashBoard()))),
                  LogoutButton()
                  /*                
                  TextButton(
                    onPressed: () {
                      _uniformSales();
                    },
                    child: const Text("Sell Uniform"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Curtainsalespage()));
                    },
                    child: const Text("Sell Curtains"),
                  ),
                  TextButton(
                      onPressed: () {
                        _newOrRepare();
                      },
                      child: const Text("Sell New Clothes")),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => StockViewWrapper(
                                    stockFilePath: stockPath)));
                      },
                      child: const Text('View Stock')),
                  TextButton(
                    child: const Text("Sales"),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SalesViewWrapper(
                                  salesFilePath:
                                      'lib/uniforms/sales/sales.json')));
                    },
                  ),
                  TextButton(
                    child: const Text("Reminders"),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ReminderPage()));
                    },
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ContactsPage()));
                      },
                      child: const Text("Contacts")),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SalesSummary()));
                      },
                      child: const Text("New Clothes Sales")),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignUpPage()));
                    },
                    child: Text("Sign Up!"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignInPage())),
                    child: Text("Sign In"),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text("Log out"),
                  )*/
                ]))
              ],
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
              child: Column(children: [
            Expanded(
                child: clothingOrder.isEmpty
                    ? const Center(
                        child: Text(
                            'No Clothing Item added yet. Add your first one!'),
                      )
                    : ListView.builder(
                        itemCount: clothingOrder.length + curtainItems.length,
                        itemBuilder: (context, index) {
                          if (index < clothingOrder.length) {
                            final order = clothingOrder[index];
                            return GestureDetector(
                                child: buildClothingItemCard(order));
                          }
                          final curtainItem =
                              curtainItems[index - clothingOrder.length];
                          return GestureDetector(
                            child: buildCurtainItemCard(curtainItem),
                          );
                        }))
          ]))
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _newOrRepare();
        },
        tooltip: 'New Clothes or Repair',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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
        title: Flexible(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(curtainItem.name), Text("Curtains")],
        )),
        subtitle: Text('Phone Number: ${curtainItem.phoneNumber}'),
        children: [
          ListTile(
            title: Text(
                'Material Owner: ${curtainItem.materialOwner == true ? 'Customer Material' : 'Tailor Material'}'),
          ),
          ListTile(
            title: Text("Curtain Type: ${curtainItem.curtainType}"),
          ),
          ListTile(
            title: Text('Notes: ${curtainItem.notes}'),
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
                    _sendPickUpNotificationCurtain(curtainItem);
                  },
                  child: Text('Ready for pickup')),
              ElevatedButton(
                  onPressed: () {
                    _showUpdateCurtainPaymentDialog(curtainItem);
                  },
                  child: Text('Update Payment'))
            ],
          )
        ],
      ),
    );
  }

  void _sendPickUpNotificationCurtain(CurtainItem clothingItem) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Pickup notification sent to ${clothingItem.name}")));
    } catch (e) {
      print('Notification error: $e');
    }
  }

  void _showUpdateCurtainPaymentDialog(CurtainItem curtainItem) async {
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
                    _processCurtainPayment(curtainItem, depositController.text,
                        paymentTypeController.text);
                    Navigator.of(context).pop();
                  },
                  child: Text("Add Payment"))
            ],
          );
        });
  }

  void _processCurtainPayment(
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

  Widget buildClothingItemCard(ClothingOrder clothingItem) {
    double totalDeposited = clothingItem.payments
        .map((entry) => double.parse((entry.amount).toStringAsFixed(2)))
        .fold(0, (a, b) => a + b);

    double originalCharges =
        double.parse((clothingItem.totalAmount).toStringAsFixed(2));
    double remainingBalance = originalCharges - totalDeposited;
    return Card(
      child: ExpansionTile(
        title: Flexible(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(clothingItem.customerName), Text("Clothing")],
        )),
        subtitle: Text('Phone Number: ${clothingItem.phoneNumber}'),
        children: [
          ListTile(
            title: Text(
                'Material Owner: ${clothingItem.materialOwner == true ? 'Customer Material' : 'Tailor Material'}'),
          ),
          ListTile(
            title: Text('Measurements: ${clothingItem.measurement}'),
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
                ...clothingItem.part.split(',').asMap().entries.map((entry) {
                  int index = entry.key;
                  String part = entry.value.trim();
                  String measurement =
                      clothingItem.measurement.split(',')[index].trim();
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
            title: Text('Charges: ${clothingItem.totalAmount}'),
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
                "Payment History(${clothingItem.payments.length} entries)"),
            children: clothingItem.payments
                .map((entry) => ListTile(
                      title: Text("Deposit: ${entry.amount}"),
                      subtitle: Text(
                          "Type: ${entry.method}, Date: ${DateFormat('yyyy-MM-dd').format(entry.timestamp)}"),
                    ))
                .toList(),
          ),
          ListTile(
            title: Text(
                'Pick Up Date: ${clothingItem.fulfillmentDate?.toIso8601String() ?? 'Not Scheduled'}'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: () {
                    _sendPickUpNotification(clothingItem);
                  },
                  child: Text('Ready for pickup')),
              ElevatedButton(
                  onPressed: () {
                    _showUpdatePaymentDialog(clothingItem);
                  },
                  child: Text('Update Payment'))
            ],
          )
        ],
      ),
    );
  }

  void _sendPickUpNotification(ClothingOrder clothingItem) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Pickup notification sent to ${clothingItem.customerName}")));
    } catch (e) {
      print('Notification error: $e');
    }
  }

  void _showUpdatePaymentDialog(ClothingOrder clothingItem) async {
    final depositController = TextEditingController();
    final paymentTypeController = TextEditingController(text: "Cash");
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Update Payment for ${clothingItem.customerName}"),
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
                    _processPayment(clothingItem, depositController.text,
                        paymentTypeController.text);
                    Navigator.of(context).pop();
                  },
                  child: Text("Add Payment"))
            ],
          );
        });
  }

  void _processPayment(ClothingOrder clothingItem, String depositAmount,
      String paymentType) async {
    try {
      final double amount = double.parse(depositAmount);
      final double newTotalPaid = clothingItem.totalPaid + amount;

      final ClothingPaymentStatus paymentStatus = _determinePaymentStatus(
          totalAmount: clothingItem.totalAmount,
          currentlyPaid: clothingItem.totalPaid,
          newPaymentAmount: amount);

      final String paymentId =
          ClothingService().generatePaymentId(clothingItem.orderName);
      final String? receiptNumber =
          paymentStatus == ClothingPaymentStatus.finalpayment
              ? "RCP-$paymentId"
              : null;

      final ClothingPayment newPayment = ClothingPayment(
        amount: amount,
        timestamp: DateTime.now(),
        method: paymentType,
        status: paymentStatus,
        receiptNumber: receiptNumber,
        recorderdBy: clothingItem.createdBy,
        paymentId: paymentId,
      );
      final updatePayment = [...clothingItem.payments, newPayment];
      final updateOrder = ClothingOrder(
          orderName: clothingItem.orderName,
          createdAt: clothingItem.createdAt,
          customerName: clothingItem.customerName,
          phoneNumber: clothingItem.phoneNumber,
          materialOwner: clothingItem.materialOwner,
           
          imageUrl: clothingItem.imageUrl,
          notes: clothingItem.notes,
          part: clothingItem.part,
          measurement: clothingItem.measurement,
          totalAmount: clothingItem.totalAmount,
          payments: clothingItem.payments,
          fulfillmentDate: clothingItem.fulfillmentDate,
          createdBy: clothingItem.createdBy);
      await ClothingService().saveClothingOrder(updateOrder);
      setState(() {
        _loadClothingItems();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Payment of $depositAmount processed successfully")));
    } catch (e) {
      print('Error processing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error processing payment: $e")));
    }
  }

  ClothingPaymentStatus _determinePaymentStatus(
      {required double totalAmount,
      required double currentlyPaid,
      required double newPaymentAmount}) {
    final double totalAfterPayment = currentlyPaid + newPaymentAmount;
    if (currentlyPaid == 0) {
      return ClothingPaymentStatus.deposit;
    } else if (totalAfterPayment >= totalAmount) {
      return ClothingPaymentStatus.finalpayment;
    } else {
      return ClothingPaymentStatus.partial;
    }
  
  }

  Future<void> _uniformSales() async {
    // Extract the uniform items from the data
    final uniformItems = uniformItemData.keys.toList();
    final stockManager = StockManager('lib/uniforms/stock/stock.json');
    final reminderManager = ReminderManager(
        reminderFilePath: 'lib/remindersystem/reminders.json',
        embroideryFilePath: 'lib/remindersystem/embroidery.json');

    // List to hold multiple entries
    List<Map<String, dynamic>> entries = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Uniform Sales"),
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
                                            entries[index]
                                                    ['selectedUniformItem'] =
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
                                            entries[index]['selectedColor'] =
                                                null;
                                            entries[index]['selectedSize'] =
                                                null;
                                            entries[index]['selectedPrize'] =
                                                null;
                                            _updateCalculatedPrice(
                                                entries, index, setState);
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
                                            .map<DropdownMenuItem<String>>(
                                                (color) {
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
                                          _updateCalculatedPrice(
                                              entries, index, setState);
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
                                            labelText: "Prize"),
                                        items: entries[index]['availablePrizes']
                                            .map<DropdownMenuItem<String>>(
                                                (prize) {
                                          return DropdownMenuItem<String>(
                                            value: prize,
                                            child: Text(prize),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            entries[index]['selectedPrize'] =
                                                newValue;
                                            _updateCalculatedPrice(
                                                entries, index, setState);
                                          });
                                        },
                                        value: entries[index]['selectedPrize'],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        readOnly: true,
                                        controller: entries[index]
                                            ['priceController'],
                                        decoration: const InputDecoration(
                                          labelText: "Price",
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle,
                                          color: Colors.red),
                                      onPressed: () => _removeEntry(
                                          entries, index, setState),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, bottom: 16),
                                  child: _buildStockStatus(
                                      context,
                                      entries[index],
                                      stockManager,
                                      reminderManager))
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      icon: const Icon(Icons.add, color: Colors.green),
                      label: const Text("Add"),
                      onPressed: () => _addNewEntry(entries, setState),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Total: ${_calculateTotalPrice(entries)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Send Quote'),
                ),
                TextButton(
                  onPressed: () async {
                    // Remove any entries with zero or invalid quantities
                    List<Map<String, dynamic>> nonEmptyEntries =
                        entries.where((entry) {
                      int? quantity =
                          int.tryParse(entry['numberController'].text);
                      return quantity != null && quantity > 0;
                    }).toList();

                    if (nonEmptyEntries.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Please add at least one item with valid quantity'),
                        backgroundColor: Colors.orange,
                      ));
                      return;
                    }

                    await _processSaleAndUpdateStock(
                      context,
                      nonEmptyEntries,
                      stockManager,
                      'sale',
                    );
                    final salesManager =
                        SalesManager('lib/uniforms/sales/sales.json');
                    await salesManager.processSale(nonEmptyEntries);
                  },
                  child: const Text("Process Sale"),
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

  Future<void> _processSaleAndUpdateStock1(BuildContext context,
      List<Map<String, dynamic>> entries, StockManager stockManager) async {
    try {
      bool success = await stockManager.processSale(entries);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator.adaptive(),
              SizedBox(width: 10),
              Text('Processing sale...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ));

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sale processed successfully'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error processing sale'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _processSaleAndUpdateStock(
      BuildContext context,
      List<Map<String, dynamic>> entries,
      StockManager stockManager,
      String currentUser) async {
    try {
      // First validate entries and calculate total
      if (entries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      // Calculate total amount first
      double totalAmount = entries.fold(
        0.0,
        (sum, entry) =>
            sum + (double.tryParse(entry['priceController'].text) ?? 0.0),
      );

      if (totalAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Total amount must be greater than 0'),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      // Process the stock update first
      bool success = await stockManager.processSale(entries);

      if (success) {
        // Show initial processing message
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator.adaptive(),
              SizedBox(width: 10),
              Text('Processing sale...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ));

        // Ask for receipt generation first
        bool generateReceipt = await showDialog<bool>(
              context: context,
              barrierDismissible: false, // Prevent outside dismissal
              builder: (context) => AlertDialog(
                title: const Text('Generate Receipt?'),
                content: const Text(
                    'Would you like to generate a receipt for this sale?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            ) ??
            false; // Default to false if dialog is dismissed

        // Always show payment dialog regardless of receipt choice
        List<PaymentEntryReciept>? payments =
            await showDialog<List<PaymentEntryReciept>>(
          context: context,
          barrierDismissible: false, // Prevent outside dismissal
          builder: (context) => PaymentCalculatorDialog(
            totalAmount: totalAmount,
          ),
        );

        // If payment was cancelled or invalid, still save the sale but mark it accordingly
        if (payments == null || payments.isEmpty) {
          payments = [
            PaymentEntryReciept(method: 'Pending', amount: totalAmount)
          ];
        }

        // Generate receipt number for both cases
        String receiptNumber = _generateReceiptNumber();

        CustomerDetails? customerDetails;
        if (generateReceipt) {
          // Only get customer details if receipt was requested
          customerDetails = await showDialog<CustomerDetails>(
            context: context,
            barrierDismissible: false,
            builder: (context) => CustomerDetailsDialog(),
          );
        }

        // Create receipt/sale record
        Receipt receipt = Receipt(
          receiptNumber: receiptNumber,
          timestamp: DateTime.now(),
          items: entries,
          totalAmount: totalAmount,
          payments: payments,
          customerDetails: customerDetails,
          servedBy: currentUser,
        );

        // Save to backend
        await _saveReceiptToBackend(receipt);

        // Send receipt if customer details were provided
        if (generateReceipt && customerDetails != null) {
          await _sendReceiptToCustomer(receipt);
        }

        // Close the sale screen
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sale processed successfully'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      print('Error in _processSaleAndUpdateStock: $e'); // For debugging
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error processing sale'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showErrorMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Error processing sale. Please try again.'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {},
          textColor: Colors.white,
        ),
      ),
    );
  }

  String _generateReceiptNumber() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(1000).toString().padLeft(3, '0');
    return 'RCP$timestamp$random';
  }

  Future<void> _saveReceiptToBackend(Receipt receipt) async {
    try {
      final receiptService = ReceiptService();
      await receiptService.saveReceipt(receipt);
      print('Receipt saved successfully'); // For debugging
    } catch (e) {
      print('Error saving receipt: $e'); // For debugging
      throw e; // Re-throw to be handled by the calling function
    }
  }

  Future<void> _sendReceiptToCustomer(Receipt receipt) async {
    //TODO
  }

  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Sale  processed successfully"),
      backgroundColor: Colors.green,
    ));
  }

  void _addNewEntry(List<Map<String, dynamic>> entries, Function setState) {
    setState(() {
      entries.add({
        'selectedUniformItem': null,
        'selectedColor': null,
        'selectedSize': null,
        'selectedPrize': null,
        'availableColors': [],
        'availableSizes': [],
        'availablePrizes': [],
        'numberController': TextEditingController(),
        'priceController': TextEditingController(),
        'calculatedPrice': 0,
      });
    });
  }

  void _removeEntry(
      List<Map<String, dynamic>> entries, int index, Function setState) {
    setState(() {
      entries.removeAt(index);
    });
  }

  void _updateCalculatedPrice(
      List<Map<String, dynamic>> entries, int index, Function setState) {
    final entry = entries[index];
    final selectedPrize = int.tryParse(entry['selectedPrize'] ?? '0') ?? 0;
    final quantity = int.tryParse(entry['numberController'].text.trim()) ?? 0;
    final calculatedPrice = selectedPrize * quantity;

    setState(() {
      entry['calculatedPrice'] = calculatedPrice;
      entry['priceController'].text = calculatedPrice.toString();
    });
  }

  int _calculateTotalPrice(List<Map<String, dynamic>> entries) {
    return entries.fold<int>(
      0,
      (sum, entry) => sum + (entry['calculatedPrice'] as int? ?? 0),
    );
  }

  Widget _buildStockStatus(BuildContext context, Map<String, dynamic> entry,
      StockManager stockManager, ReminderManager reminderManager) {
    if (entry['selectedUniformItem'] == null ||
        entry['selectedColor'] == null ||
        entry['selectedSize'] == null) {
      return const SizedBox.shrink();
    }

    final stockStatus = stockManager.checkStockStatus(
        entry['selectedUniformItem'],
        entry['selectedColor'],
        entry['selectedSize']);

    final currentStock = stockManager.getCurrentStock(
        entry['selectedUniformItem'],
        entry['selectedColor'],
        entry['selectedSize']);

    switch (stockStatus) {
      case StockStatus.outOfStock:
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: const Text(
            'Out of Stock',
            style: TextStyle(color: Colors.red),
          ),
        );

      case StockStatus.low:
        return Container(
          margin: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Text(
                'Stock: $currentStock',
                style: const TextStyle(color: Colors.orange),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                icon: const Icon(Icons.warning_amber_rounded, size: 18),
                label: const Text('Request Item'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange.shade50,
                  foregroundColor: Colors.orange.shade900,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: () async {
                  await reminderManager.addReminder(
                    type: ReminderType.stockAlert,
                    title: 'Low Stock Alert: ${entry['selectedUniformItem']}',
                    description: 'Color: ${entry['selectedColor']}\n'
                        'Size: ${entry['selectedSize']}\n'
                        'Current Stock: $currentStock',
                    dueDate: null,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stock request reminder created'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ],
          ),
        );

      case StockStatus.available:
        return Container(
          margin: const EdgeInsets.only(top: 8),
          child: Text(
            'Stock: $currentStock',
            style: const TextStyle(color: Colors.green),
          ),
        );
    }
  }

  Future<void> _uniformSales2() async {
    final uniformItems = uniformItemData.keys.toList();
    List<Map<String, dynamic>> entries = [];
    final stockManager = StockManager('lib/uniforms/stock.json');

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            void addNewEntry() {
              setState(() {
                entries.add({
                  'selectedUniformItem': null,
                  'selectedColor': null,
                  'selectedSize': null,
                  'selectedPrize': null,
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
              final selectedPrize =
                  int.tryParse(entry['selectedPrize'] ?? '0') ?? 0;
              final quantity =
                  int.tryParse(entry['numberController'].text.trim()) ?? 0;
              final calculatedPrice = selectedPrize * quantity;

              setState(() {
                entry['calculatedPrice'] = calculatedPrice;
                entry['priceController'].text = calculatedPrice.toString();
              });
            }

            int calculateTotalPrice() {
              return entries.fold<int>(
                0,
                (sum, entry) => sum + (entry['calculatedPrice'] as int? ?? 0),
              );
            }

            Future<void> processSaleAndUpdateStock() async {
              try {
                bool success = await stockManager.processSale(entries);
                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Row(
                      children: [
                        CircularProgressIndicator.adaptive(),
                        SizedBox(
                          width: 10,
                        ),
                        Text('Processing sale...'),
                      ],
                    ),
                    duration: Duration(seconds: 1),
                  ));

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Sale processed successfully'),
                    backgroundColor: Colors.green,
                  ));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Error processing sale'),
                  backgroundColor: Colors.red,
                ));
              }
            }

            return AlertDialog(
              title: const Text("Uniform Sales"),
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
                                          items:
                                              uniformItems.map((String item) {
                                            return DropdownMenuItem<String>(
                                              value: item,
                                              child: Text(item),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              entries[index]
                                                      ['selectedUniformItem'] =
                                                  newValue;
                                              entries[index]
                                                      ['availableColors'] =
                                                  uniformItemData[newValue]![
                                                      'colors']!;
                                              entries[index]['availableSizes'] =
                                                  uniformItemData[newValue]![
                                                      'sizes']!;
                                              entries[index]
                                                      ['availablePrizes'] =
                                                  uniformItemData[newValue]![
                                                      'prizes']!;
                                              entries[index]['selectedColor'] =
                                                  null;
                                              entries[index]['selectedSize'] =
                                                  null;
                                              entries[index]['selectedPrize'] =
                                                  null;
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
                                              entries[index]['selectedColor'] =
                                                  newValue;
                                            });
                                          },
                                          value: entries[index]
                                              ['selectedColor'],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
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
                                            if (value == null ||
                                                value.isEmpty) {
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
                                              labelText: "Prize"),
                                          items: entries[index]
                                                  ['availablePrizes']
                                              .map<DropdownMenuItem<String>>(
                                                  (prize) {
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
                                          value: entries[index]
                                              ['selectedPrize'],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          readOnly: true,
                                          controller: entries[index]
                                              ['priceController'],
                                          decoration: const InputDecoration(
                                            labelText: "Price",
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: Colors.red),
                                        onPressed: () => removeEntry(index),
                                      ),
                                    ],
                                  ),
                                );
                              }))
                    ],
                  )),
              actions: [
                TextButton(onPressed: () {}, child: const Text("Send Quote")),
                TextButton(
                    onPressed: () async {
                      bool isValid = true;
                      for (var entry in entries) {
                        if (entry['selectedUnifromItme'] == null ||
                            entry['selectedColor'] == null ||
                            entry['selectedSize'] == null ||
                            entry['numberController'].text.isEmpty ||
                            int.tryParse(entry['numberController'].text) ==
                                null) {
                          isValid = false;
                          break;
                        }
                      }
                      if (isValid) {
                        await processSaleAndUpdateStock();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Ensure all fields are filled with valid inputs')));
                      }
                    },
                    child: const Text('Process Sale')),
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

  Future<void> _promptPayment() async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text('Prompt Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MpesaPaymentScreen()));
                      },
                      child: Text("Lipa na Mpesa"))
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
                        child: const Text('cancel')),
                    ElevatedButton(
                        onPressed: () {}, child: const Text('Prompt'))
                  ],
                )
              ],
            );
          });
        });
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
              final selectedPrize =
                  int.tryParse(entry['selectedPrize'] ?? '0') ?? 0;
              final quantity =
                  int.tryParse(entry['numberController'].text.trim()) ?? 0;
              final calculatedPrice = selectedPrize * quantity;

              setState(() {
                entry['calculatedPrice'] = calculatedPrice;
                entry['priceController'].text = calculatedPrice.toString();
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
                              null) {
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

                        print('Price: ${entry['calculatedPrice']}');
                      }
                      Navigator.of(context).pop();
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
