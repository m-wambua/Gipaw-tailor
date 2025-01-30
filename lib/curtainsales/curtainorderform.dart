import 'package:flutter/material.dart';
import 'package:gipaw_tailor/curtainsales/curtainsmodel.dart';
import 'package:intl/intl.dart';

class CurtainOrderForm extends StatefulWidget {
  const CurtainOrderForm({Key? key}) : super(key: key);

  @override
  State<CurtainOrderForm> createState() => _CurtainOrderFormState();
}

class _CurtainOrderFormState extends State<CurtainOrderForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Text editing controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _materialOwnerController = TextEditingController();
  final _curtainTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _measurementsController = TextEditingController();
  final _partController = TextEditingController();
  final _measurementController = TextEditingController();
  final _chargesController = TextEditingController();
  final _depositController = TextEditingController();
  
  DateTime _orderDate = DateTime.now();
  String _selectedPaymentMethod = 'Cash';
  
  final List<String> _paymentMethods = ['Cash', 'M-Pesa', 'Bank Transfer', 'Card'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _materialOwnerController.dispose();
    _curtainTypeController.dispose();
    _descriptionController.dispose();
    _measurementsController.dispose();
    _partController.dispose();
    _measurementController.dispose();
    _chargesController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _orderDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _orderDate) {
      setState(() {
        _orderDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Create a new CurtainItem
      final curtainItem = CurtainItem(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        materialOwner: _materialOwnerController.text,
        curtainType: _curtainTypeController.text,
        description: _descriptionController.text,
        notes: _measurementsController.text,
        part: _partController.text,
        measurement: _measurementController.text,
        charges: _chargesController.text,
        orderDate: _orderDate,
      );

      // Create initial payment entry
      if (_depositController.text.isNotEmpty) {
        final payment = CurtainpaymentEntry(
          deposit: _depositController.text,
          balance: CurtainpaymentEntry.calculateBalance(
            _chargesController.text,
            _depositController.text,
          ),
          paymentDate: DateTime.now(),
          paymentMethod: _selectedPaymentMethod,
        );
        curtainItem.curtainPaymentEntries = [payment];
      }

      // TODO: Save the curtain item using CurtainManager
      // CurtainManager.saveCurtainItem([curtainItem]);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Curtain Order'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Information Section
                const Text(
                  'Customer Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter customer name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                
                // Curtain Details Section
                const SizedBox(height: 24),
                const Text(
                  'Curtain Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _materialOwnerController,
                  decoration: const InputDecoration(
                    labelText: 'Material Owner',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _curtainTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Curtain Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                
                // Measurements Section
                const SizedBox(height: 24),
                const Text(
                  'Measurements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _measurementsController,
                  decoration: const InputDecoration(
                    labelText: 'Measurements',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _partController,
                  decoration: const InputDecoration(
                    labelText: 'Part',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _measurementController,
                  decoration: const InputDecoration(
                    labelText: 'Measurement',
                    border: OutlineInputBorder(),
                  ),
                ),

                // Payment Section
                const SizedBox(height: 24),
                const Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _chargesController,
                  decoration: const InputDecoration(
                    labelText: 'Total Charges',
                    border: OutlineInputBorder(),
                    prefixText: 'Ksh ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter charges';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _depositController,
                  decoration: const InputDecoration(
                    labelText: 'Deposit Amount',
                    border: OutlineInputBorder(),
                    prefixText: 'Ksh ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedPaymentMethod,
                  items: _paymentMethods.map((String method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPaymentMethod = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Order Date'),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy').format(_orderDate),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                
                // Submit Button
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Save Order'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}