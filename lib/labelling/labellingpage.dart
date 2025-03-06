import 'package:flutter/material.dart';
import 'package:gipaw_tailor/labelling/labellingmethod.dart';
import 'package:intl/intl.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Labelling Page'),
      ),
      body: Column(
        children: [],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _newLabel();
        },
        tooltip: 'New Label',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _newLabel() async {
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
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }
}
