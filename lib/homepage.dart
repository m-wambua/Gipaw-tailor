import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gipaw_tailor/clothesentrymodel/newandrepare.dart';

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
  int _counter = 0;
  final _namecontroller = TextEditingController();
  final _phoneNumbercontroller = TextEditingController();
  final _measurementsController = TextEditingController();
  final _chargesController = TextEditingController();
  final _commentsController = TextEditingController();

  List<ClothingItem> clothingItems = [];

  @override
  void initState() {
    super.initState();
    _loadClothingItems();
  }

  Future<void> _loadClothingItems() async {
    try {
      final loadedClothingItems = await ClotthingManager.loadClothingItems();
      setState(() {
        clothingItems = loadedClothingItems;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clothing items')));
    }
  }

  @override
  void _newPiece(String newClothing) async {
    final _formKey = GlobalKey<FormState>();
    List<Map<String, TextEditingController>> paymentPairs = [
      {'deposit': TextEditingController(), 'balance': TextEditingController()}
    ];

    bool _materialOwner = false;

    await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                scrollable: true,
                title: Text('Create New Clothing Item'),
                content: Form(
                    key: _formKey,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Radio(
                              value: true,
                              groupValue: _materialOwner,
                              onChanged: (value) {
                                setState(() {
                                  _materialOwner = value!;
                                });
                              },
                            ),
                            Text("Customer Material"),
                            Radio(
                                value: false,
                                groupValue: _materialOwner,
                                onChanged: (value) {
                                  setState(() {
                                    _materialOwner = value!;
                                  });
                                }),
                            Text("Own Material"),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
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
                            child: Text('Add Sample')),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          controller: _chargesController,
                          decoration: InputDecoration(labelText: 'Charges'),
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter a charge' : null,
                        ),
                        SizedBox(
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
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: pair['deposit'],
                                          decoration: InputDecoration(
                                            labelText: 'Deposit ${index + 1}',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: TextField(
                                          controller: pair['balance'],
                                          decoration: InputDecoration(
                                            labelText: 'Balance ${index + 1}',
                                            border: OutlineInputBorder(),
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
                                    icon: Icon(Icons.remove)),
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
                                    icon: Icon(Icons.add))
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
                            child: Text('Pick up date'))
                      ],
                    )),
                actions: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: () {},
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          )),
                      ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              List<PaymentEntry> payments = paymentPairs
                                  .map((pair) => PaymentEntry(
                                      deposit: pair['deposit']!.text,
                                      balance: pair['balance']!.text))
                                  .toList();
                              ClothingItem newItem = ClothingItem(
                                name: _namecontroller.text,
                                phoneNumber: _phoneNumbercontroller.text,
                                materialOwner: _materialOwner,
                                measurements: _measurementsController.text,
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
                          child: Text(
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

    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              scrollable: true,
              title: Text('Create New Clothing Item'),
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
                      child: Text('Add Sample')),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Charges'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a charge' : null,
                  ),
                  SizedBox(
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
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: pair['balance'],
                                    decoration: InputDecoration(
                                      labelText: 'Balance ${index + 1}',
                                      border: OutlineInputBorder(),
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
                              icon: Icon(Icons.remove)),
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
                              icon: Icon(Icons.add))
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
                      child: Text('Pick up date'))
                ],
              )),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () {},
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        )),
                    ElevatedButton(
                        onPressed: () {},
                        child: Text(
                          'Save',
                          style: TextStyle(color: Colors.green),
                        ))
                  ],
                )
              ],
            ));
  }

  Future<void> _addSample() async {
    showDialog(
        context: context as BuildContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add sample'),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Take a photo'),
                IconButton(onPressed: () {}, icon: Icon(Icons.photo))
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
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      )),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
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
            title: Text('New Piece or Repair'),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                    onPressed: () {
                      _newPiece("New Clothing");
                    },
                    child: Text('New Piece')),
                ElevatedButton(
                    onPressed: () {
                      _repair("Repair");
                    },
                    child: Text('Repair'))
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
                      child: Text(
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Welcome to Gipaw Tailor"),
      ),
      body: Column(children: [
        Expanded(
            child: clothingItems.isEmpty
                ? const Center(
                    child:
                        Text('No Clothing Item added yet. Add your first one!'),
                  )
                : ListView.builder(
                    itemCount: clothingItems.length,
                    itemBuilder: (context, index) {
                      final clothingItem = clothingItems[index];
                      return GestureDetector(
                        child: Card(
                          child: ExpansionTile(
                            title: Text(clothingItem.name),
                            subtitle: Text(
                                'Phone Number: ${clothingItem.phoneNumber}'),
                            children: [
                              ListTile(
                                title: Text(
                                    'Material Owner ${clothingItem.materialOwner}'),
                              ),
                              ListTile(
                                title: Text(
                                    'Measurements: ${clothingItem.measurements}'),
                              ),
                              ListTile(
                                title: Text('Charged: ${clothingItem.charges}'),
                              ),
                              ListTile(
                                title: Text(
                                    'Deposit Paid ${clothingItem.paymentEntries}'),
                              ),
                              ListTile(
                                title: Text(
                                    'Balance: ${clothingItem.paymentEntries}'),
                              )
                            ],
                          ),
                        ),
                      );
                    }))
      ]),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _newOrRepare();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
