import 'package:flutter/material.dart';
import 'package:gipaw_tailor/receipts/receipts.dart';
import 'package:gipaw_tailor/receipts/receiptservice.dart';
import 'package:intl/intl.dart';

class ReceiptPage extends StatefulWidget {
  @override
  _ReceiptPageState createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final ReceiptService _receiptService = ReceiptService();
  List<Receipt> _receipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);
    try {
      final receipts = await _receiptService.getAllReceipts();
      setState(() {
        _receipts = receipts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading Receipts: $e')));
    }
    ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Receipts'),
          actions: [
            IconButton(onPressed: _loadReceipts, icon: Icon(Icons.refresh))
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _receipts.isEmpty
                ? const Center(
                    child: Text('No receipts found '),
                  )
                : ListView.builder(
                    itemCount: _receipts.length,
                    itemBuilder: (context, index) {
                      final receipt = _receipts[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                            title: Text('Receipt ~${receipt.receiptNumber}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(receipt.timestamp)}'),
                                Text(
                                  'Amount: \$${receipt.totalAmount.toStringAsFixed(2)}',
                                ),
                                if (receipt.customerDetails?.name != null)
                                  Text(
                                      'Customer: ${receipt.customerDetails?.name}'),
                                if (receipt.customerDetails?.email != null)
                                  Text(
                                      'Email: ${receipt.customerDetails?.email}'),
                                if (receipt.customerDetails?.phone != null)
                                  Text(
                                      'Phone: ${receipt.customerDetails?.phone}'),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showReceiptDetails(receipt)),
                      );
                    },
                  ));
  }

  void _showReceiptDetails(Receipt receipt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Receipt #${receipt.receiptNumber}'),
        content: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(
                'Date: ${DateFormat('MMM dd, yyyy HH:mm').format(receipt.timestamp)}',
              ),
              const SizedBox(
                height: 8,
              ),
              Text('Servec by: ${receipt.servedBy}'),
              const SizedBox(
                height: 16,
              ),
              if (receipt.customerDetails != null) ...[
                const Text(
                  'Customer Details: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Name: ${receipt.customerDetails?.name ?? 'N/A'}'),
                Text('Email: ${receipt.customerDetails?.email ?? 'N/A'}'),
                Text('Phone: ${receipt.customerDetails?.phone ?? 'N/A'}'),
                const SizedBox(
                  height: 16,
                ),
              ],
              const Text(
                'Items: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...receipt.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${item['selectedUniformItem']} - ${item['selectedColor']} - ${item['selectedSize']}\n'
                      'Quantity: ${item['numberController'].text}\n'
                      'Price: KES${item['priceController'].text}',
                    ),
                  )),
              const SizedBox(
                height: 16,
              ),
              const Text(
                'Payments: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...receipt.payments.map((payment) => Text(
                  '${payment.method} : KES${payment.amount.toStringAsFixed(2)}' +
                      (payment.givenAmount != null
                          ? '\nChange: KES${(payment.givenAmount! - payment.amount).toStringAsFixed(2)}'
                          : ''))),
              const SizedBox(
                height: 16,
              ),
              Text('Total Amount: KES${receipt.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }
}
