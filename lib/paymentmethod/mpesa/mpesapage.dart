import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MpesaPaymentScreen extends StatefulWidget {
  const MpesaPaymentScreen({super.key});
  @override
  _MpesaPaymentScreenState createState() => _MpesaPaymentScreenState();
}

class _MpesaPaymentScreenState extends State<MpesaPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _isLoading = false;
  String? _status;

  final String apiUrl = 'http://yout-api-domin.com/api/mpesa/stkpush';

  Future<void> _initiateSTKPush() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _status = null;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': _phoneNumberController.text,
          'amount': double.parse(_amountController.text),
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          _status = 'Payment Initiated! Please check your phone.';
        });
      } else {
        final error = json.decode(response.body);
        setState(() {
          _status = "Error: ${error['detail'] ?? "Failed to initiate payment"}";
        });
      }
    } catch (e) {
      setState(() {
        _status = "Error: Could not connect to the server";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M-Pesa Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '254712345678',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    // Basic phone number validation
                    String cleanedNumber = value.replaceAll(RegExp(r'\D'), '');
                    if (!cleanedNumber.startsWith('254')) {
                      return 'Phone number must start with 254';
                    }
                    if (cleanedNumber.length != 12) {
                      return 'Invalid phone number length';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: "Amount (KES)",
                    hintText: "Enter amount",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _initiateSTKPush,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text("Processing...."),
                          ],
                        )
                      : const Text('Pay with M-PESA'),
                ),
                if (_status != null) ...[
                  const SizedBox(
                    height: 16,
                  ),
                  Text(
                    _status!,
                    style: TextStyle(
                        color: _status!.contains("Error")
                            ? Colors.red
                            : Colors.green),
                    textAlign: TextAlign.center,
                  )
                ]
              ],
            )),
      ),
    );
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
