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
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final deleted = provider.deletedTransactions;

        if (deleted.isEmpty) {
          return const Center(
            child: Text('No deleted transactions.'),
          );
        }

        return ListView.builder(
          itemCount: deleted.length,
          itemBuilder: (context, index) {
            final t = deleted[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              elevation: 1,
              color: Colors.grey.shade200,
              child: ListTile(
                leading: Icon(
                  t.type == "Income" ? Icons.arrow_downward : Icons.arrow_upward,
                  color: t.type == "Income" ? Colors.green : Colors.red,
                ),
                title: Text(
                  t.category,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(_formatDate(t.date)),
                trailing: Text(
                  '${t.type == "Income" ? "+" : "-"}₹${t.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color:
                        t.type == "Income" ? Colors.green : Colors.redAccent,
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
