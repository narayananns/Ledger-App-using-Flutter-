import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final deletedList = provider.deletedTransactions;

        if (deletedList.isEmpty) {
          return const Center(
            child: Text('No deleted transactions.'),
          );
        }

        return ListView.builder(
          itemCount: deletedList.length,
          itemBuilder: (context, index) {
            final txn = deletedList[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: Colors.grey.shade100,
              child: ListTile(
                leading: Icon(
                  txn.type == 'Income'
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: txn.type == 'Income' ? Colors.green : Colors.red,
                ),
                title: Text(
                  txn.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(_formatDate(txn.date)),
                trailing: Text(
                  '${txn.type == 'Income' ? '+' : '-'}₹${txn.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color:
                        txn.type == 'Income' ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
