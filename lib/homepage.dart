import 'package:flutter/material.dart';
import 'package:gipaw_tailor/clothesentrymodel/clothingandrepairsales.dart';
import 'package:gipaw_tailor/clothesentrymodel/newandrepare.dart';
import 'package:gipaw_tailor/contacts/contactspage.dart';
import 'package:gipaw_tailor/curtainsales/curtainorderform.dart';
import 'package:gipaw_tailor/curtainsales/curtainsalespage.dart';
import 'package:gipaw_tailor/curtainsales/curtainsmodel.dart';
import 'package:gipaw_tailor/paymentmethod/mpesa/mpesapage.dart';
import 'package:gipaw_tailor/remindersystem/reminderclass.dart';
import 'package:gipaw_tailor/remindersystem/reminderpage.dart';
import 'package:gipaw_tailor/signinpage/admindash.dart';
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

  final List<UserRole> allowedRoles = [];

  final double sidebarWidth = 250.0;

  List<ClothingItem> clothingItems = [];
  List<CurtainItem> curtainItems = [];

  @override
  void initState() {
    super.initState();
    _loadClothingItems();
    _loadCurtainItems();
  }

  Future<void> _loadClothingItems() async {
    try {
      final loadedClothingItems = await ClotthingManager.loadClothingItems();
      setState(() {
        clothingItems = loadedClothingItems;
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
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              List<PaymentEntry> payments = paymentPairs
                                  .map(
                                    (pair) => PaymentEntry(
                                        deposit: pair['deposit']!.text,
                                        balance: pair['balance']!.text,
                                        paymentDate: pair['paymentDate'],
                                        paymentType: pair['paymentType']),
                                  )
                                  .toList();
                              ClothingItem newItem = ClothingItem(
                                name: _namecontroller.text,
                                phoneNumber: _phoneNumbercontroller.text,
                                materialOwner: materialOwner,
                                measurements: _measurementsController.text,
                                part: measurementPairs
                                    .map((pair) => pair['part']!.text)
                                    .join(','),
                                measurement: measurementPairs
                                    .map((pair) => pair['measurement']!.text)
                                    .join(','),
                                charges: _chargesController.text,
                                paymentEntries: payments,
                              );
                              setState(() {
                                clothingItems.add(newItem);
                              });

                              String clothingItemName =
                                  ClothingItemIdentifier.generateIdentifier(
                                      _namecontroller.text,
                                      _phoneNumbercontroller.text);
                              ClotthingManager.saveClothingItem(clothingItems);
                            }
                            setState(() {
                              _loadClothingItems();
                            });
                          },
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
                              builder: (context) => AdminDashBoard())))
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
                child: clothingItems.isEmpty
                    ? const Center(
                        child: Text(
                            'No Clothing Item added yet. Add your first one!'),
                      )
                    : ListView.builder(
                        itemCount: clothingItems.length + curtainItems.length,
                        itemBuilder: (context, index) {
                          if (index < clothingItems.length) {
                            final clothingItem = clothingItems[index];
                            return GestureDetector(
                                child: buildClothingItemCard(clothingItem));
                          }
                          final curtainItem =
                              curtainItems[index - clothingItems.length];
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

  Widget buildClothingItemCard(ClothingItem clothingItem) {
    double totalDeposited = clothingItem.paymentEntries
        .map((entry) => double.parse(entry.deposit))
        .fold(0, (a, b) => a + b);

    double originalCharges = double.parse(clothingItem.charges);
    double remainingBalance = originalCharges - totalDeposited;
    return Card(
      child: ExpansionTile(
        title: Flexible(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(clothingItem.name), Text("Clothing")],
        )),
        subtitle: Text('Phone Number: ${clothingItem.phoneNumber}'),
        children: [
          ListTile(
            title: Text(
                'Material Owner: ${clothingItem.materialOwner ? 'Customer Material' : 'Tailor Material'}'),
          ),
          ListTile(
            title: Text('Measurements: ${clothingItem.measurements}'),
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
            title: Text('Charges: ${clothingItem.charges}'),
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
                "Payment History(${clothingItem.paymentEntries.length} entries)"),
            children: clothingItem.paymentEntries
                .map((entry) => ListTile(
                      title: Text("Deposit: ${entry.deposit}"),
                      subtitle: Text(
                          "Type: ${entry.paymentType}, Date: ${DateFormat('yyyy-MM-dd').format(entry.paymentDate)}"),
                    ))
                .toList(),
          ),
          ListTile(
            title: Text(
                'Pick Up Date: ${clothingItem.pickUpDate?.toIso8601String() ?? 'Not Scheduled'}'),
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

  void _sendPickUpNotification(ClothingItem clothingItem) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Pickup notification sent to ${clothingItem.name}")));
    } catch (e) {
      print('Notification error: $e');
    }
  }

  void _showUpdatePaymentDialog(ClothingItem clothingItem) async {
    final depositController = TextEditingController();
    final paymentTypeController = TextEditingController(text: "Cash");
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Update Payment for ${clothingItem.name}"),
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

  void _processPayment(ClothingItem clothingItem, String depositAmount,
      String paymentType) async {
    PaymentEntry newPayment = PaymentEntry(
      deposit: depositAmount,
      balance: (double.parse(clothingItem.charges) -
              (clothingItem.paymentEntries
                      .fold(0, (sum, entry) => sum + int.parse(entry.deposit)) +
                  double.parse(depositAmount)))
          .toString(),
      paymentDate: DateTime.now(),
      paymentType: paymentType,
    );

    clothingItem.paymentEntries.add(newPayment);
    ClotthingManager.saveClothingItem(clothingItems);
    setState(() {
      _loadClothingItems();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Payment of $depositAmount processed'),
    ));
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

            Widget buildStockStatus(Map<String, dynamic> entry) {
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          icon:
                              const Icon(Icons.warning_amber_rounded, size: 18),
                          label: const Text('Request Item'),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.orange.shade50,
                            foregroundColor: Colors.orange.shade900,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                          onPressed: () async {
                            await reminderManager.addReminder(
                              type: ReminderType.stockAlert,
                              title:
                                  'Low Stock Alert: ${entry['selectedUniformItem']}',
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
                                            updateCalculatedPrice(index);
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
                                      onPressed: () => removeEntry(index),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8, bottom: 16),
                                  child: buildStockStatus(entries[index]))
                            ],
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
                    Text(
                      "Total: ${calculateTotalPrice()}",
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
                    bool isValid = true;
                    for (var entry in entries) {
                      if (entry['selectedUniformItem'] == null ||
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
                      final salesManager =
                          SalesManager('lib/uniforms/sales/sales.json');
                      await salesManager.processSale(entries);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Please fill all fields with valid inputs'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
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
