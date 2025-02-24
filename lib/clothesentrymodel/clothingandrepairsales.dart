import 'package:flutter/material.dart';
import 'package:gipaw_tailor/clothesentrymodel/newandrepare.dart';
import 'package:intl/intl.dart';

class SalesSummary extends StatefulWidget {
  const SalesSummary({super.key});

  @override
  State<SalesSummary> createState() => _SalesSummaryState();
}

class _SalesSummaryState extends State<SalesSummary> {
  DateTimeRange? _selectedDateRange;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Summary'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
// TODO: implement build
    return FutureBuilder<List<ClothingOrder>>(
        future: ClothingService().getAllClothingOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          final filteredItems =
              filterItemsByDateRange(items, _selectedDateRange);
          final totalSales = ClothingService().calculateTotalSales(items);
          final paymentTypeBreakdown =
              ClothingService().getPaymentMethodsBreakDown(items);
          final pendingBalances = ClothingService().getPendingBalances(items);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRangePicker(context),
                  _buildSummaryCard(
                    'Total Sales',
                    'KES ${totalSales.toStringAsFixed(2)}',
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  _buildPaymentTypeBreakdown(paymentTypeBreakdown),
                  const SizedBox(
                    height: 16,
                  ),
                  //_buildPendingBalances(pendingBalances),
                  buildPaymentSummaryTable(items)
                ],
              ),
            ),
          );
        });
  }

  Widget _buildDateRangePicker(BuildContext context) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text(
                "Time Period",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(_selectedDateRange != null
                        ? '${DateFormat('MMM d, y').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, y').format(_selectedDateRange!.end)}'
                        : 'All Time'),
                  ),
                  TextButton(
                    onPressed: () => _selectDateRange(context),
                    child: const Text('Select Date Range'),
                  ),
                  if (_selectDateRange != null)
                    TextButton(
                      onPressed: () =>
                          setState(() => _selectedDateRange = null),
                      child: const Text('Clear'),
                    ),
                ],
              )
            ])));
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  String _getDateRangeText() {
    if (_selectedDateRange == null) return '';
    return ' (${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)})';
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeBreakdown(Map<String, double> breakdown) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Type Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...breakdown.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text('KES ${entry.value.toStringAsFixed(2)}'),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
  /*

  Widget _buildPendingBalances(List<PendingBalance> pendingBalances) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending Balances',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...pendingBalances.map((balance) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(flex: 2, child: Text(balance.customerName)),
                      Expanded(
                        child: Text('KES ${balance.amount.toStringAsFixed(2)}'),
                      )
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
  */

  Widget buildPaymentSummaryTable(List<ClothingOrder> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Customer Name')),
                  DataColumn(label: Text('Phone Number')),
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('Amount Charged')),
                  DataColumn(label: Text('Amount Paid')),
                  DataColumn(label: Text('Balance')),
                  DataColumn(label: Text('Payment Method')),
                  DataColumn(label: Text('Last Payment Date')),
                ],
                rows: items.map((item) {
                  // Calculate total paid amount
                  double totalPaid = item.payments.fold(
                    0.0,
                    (sum, payment) =>
                        sum + double.parse((payment.amount).toStringAsFixed(2)),
                  );

                  // Calculate remaining balance
                  double totalCharged =
                      double.parse((item.totalAmount).toStringAsFixed(2));
                  double remainingBalance = totalCharged - totalPaid;

                  // Get last payment method and date
                  String lastPaymentMethod = item.payments.isNotEmpty
                      ? item.payments.last.method
                      : 'N/A';

                  String lastPaymentDate = item.payments.isNotEmpty
                      ? _formatDate(item.payments.last.timestamp)
                      : 'N/A';

                  return DataRow(
                    cells: [
                      DataCell(Text(item.customerName)),
                      DataCell(Text(item.phoneNumber)),
                      DataCell(Text(item.measurement)),
                      DataCell(Text('KES ${totalCharged.toStringAsFixed(2)}')),
                      DataCell(Text('KES ${totalPaid.toStringAsFixed(2)}')),
                      DataCell(Text(
                        'KES ${remainingBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color:
                              remainingBalance > 0 ? Colors.red : Colors.green,
                          fontWeight: remainingBalance > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      )),
                      DataCell(Text(lastPaymentMethod)),
                      DataCell(Text(lastPaymentDate)),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryFooter(items),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryFooter(List<ClothingOrder> items) {
    double totalCharged = items.fold(
        0.0,
        (sum, item) =>
            sum + double.parse((item.totalAmount).toStringAsFixed(2)));

    double totalPaid = items.fold(
        0.0,
        (sum, item) =>
            sum +
            item.payments.fold(
                0.0,
                (paymentSum, payment) =>
                    paymentSum +
                    double.parse((payment.amount).toStringAsFixed(2))));

    double totalBalance = totalCharged - totalPaid;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total Charged: KES ${totalCharged.toStringAsFixed(2)} | '
                'Total Paid: KES ${totalPaid.toStringAsFixed(2)} | '
                'Total Outstanding: KES ${totalBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  List<ClothingOrder> filterItemsByDateRange(
      List<ClothingOrder> items, DateTimeRange? range) {
    if (range == null) return items;

    return items.where((item) {
      final hasPaymentsInRange = item.payments.any((payment) =>
          payment.timestamp.isAfter(range.start) &&
          payment.timestamp.isBefore(range.end.add(const Duration(days: 1))));
      return hasPaymentsInRange;
    }).toList();
  }
}
