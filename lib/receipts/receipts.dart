import 'package:flutter/material.dart';

class PaymentEntryReciept {
  final String method;
  final double amount;
  final double? givenAmount;
  PaymentEntryReciept(
      {required this.method, required this.amount, this.givenAmount});
}

class CustomerDetails {
  final String? name;
  final String? email;
  final String? phone;
  CustomerDetails({this.name, this.email, this.phone});
}

class Receipt {
  final String receiptNumber;
  final DateTime timestamp;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final List<PaymentEntryReciept> payments;
  final CustomerDetails? customerDetails;
  final String servedBy;

  Receipt({
    required this.receiptNumber,
    required this.timestamp,
    required this.items,
    required this.totalAmount,
    required this.payments,
    this.customerDetails,
    required this.servedBy,
  });
}

class PaymentCalculatorDialog extends StatefulWidget {
  final double totalAmount;

  const PaymentCalculatorDialog({
    super.key,
    required this.totalAmount,
  });

  @override
  State<PaymentCalculatorDialog> createState() =>
      _PaymentCalculatorDialogState();
}

class _PaymentCalculatorDialogState extends State<PaymentCalculatorDialog> {
  List<PaymentEntryReciept> payments = [];
  double remainingAmount = 0;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    remainingAmount = widget.totalAmount;
  }

  void addPayment(String method, double amount, {double? givenAmount}) {
    if (amount <= 0) {
      setState(() {
        errorMessage = 'Amount must be greater than 0';
      });
      return;
    }

    if (amount > remainingAmount) {
      setState(() {
        errorMessage = 'Amount cannot exceed remaining balance';
      });
      return;
    }

    setState(() {
      payments.add(PaymentEntryReciept(
          method: method, amount: amount, givenAmount: givenAmount));
      remainingAmount -= amount;
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Amount: \$${widget.totalAmount.toStringAsFixed(2)}'),
            Text('Remaining: \$${remainingAmount.toStringAsFixed(2)}'),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 10),
            // Payment method buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: ['MPesa', 'Cash', 'Card'].map((method) {
                  return ElevatedButton(
                    onPressed: remainingAmount > 0
                        ? () => _showAmountInput(method)
                        : null,
                    child: Text(method),
                  );
                }).toList(),
              ),
            ),

            if (payments.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...payments.map((payment) => ListTile(
                    title: Text(
                        '${payment.method}: \$${payment.amount.toStringAsFixed(2)}${payment.givenAmount != null
                                ? '\nChange: \$${(payment.givenAmount! - payment.amount).toStringAsFixed(2)}'
                                : ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          remainingAmount += payment.amount;
                          payments.remove(payment);
                        });
                      },
                    ),
                  )),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: remainingAmount == 0
              ? () => Navigator.pop(context, payments)
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  void _showAmountInput(String method) {
    showDialog(
        context: context,
        builder: (context) {
          TextEditingController amountController = TextEditingController();
          TextEditingController givenAmountController = TextEditingController();
          return StatefulBuilder(builder: (context, setState) {
            double? amount = double.tryParse(amountController.text);
            double? givenAmount = double.tryParse(givenAmountController.text);
            double? change = givenAmount != null && amount != null
                ? givenAmount - amount
                : null;

            return AlertDialog(
              title: Text('Enter $method Amount'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount to pay',
                    prefixText: '\$',
                  ),
                ),
                if (method == 'Cash') ...[
                  const SizedBox(height: 10),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: givenAmountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount Given',
                      prefixText: '\$',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (change != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Change: \$${change.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: change < 0 ? Colors.red : Colors.green),
                    )
                  ],
                ]
              ]),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    double? amount = double.tryParse(amountController.text);
                    if (amount != null) {
                      addPayment(method, amount);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
            // Add simple calculator for cash
            // You can expand this part based on your needs
          });
        });
  }
}

class CustomerDetailsDialog extends StatefulWidget {
  const CustomerDetailsDialog({super.key});

  @override
  State<CustomerDetailsDialog> createState() => _CustomerDetailsDialogState();
}

class _CustomerDetailsDialogState extends State<CustomerDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  String? name;
  String? email;
  String? phone;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Customer Details'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Name'),
              onSaved: (value) => name = value,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onSaved: (value) => email = value,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              onSaved: (value) => phone = value,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              if (name != null || email != null || phone != null) {
                Navigator.pop(
                  context,
                  CustomerDetails(
                    name: name,
                    email: email,
                    phone: phone,
                  ),
                );
              }
            }
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
