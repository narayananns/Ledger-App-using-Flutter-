import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';

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

  void _showRestoreDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: const [
              Icon(Icons.restore, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                "Restore Transaction",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          content: const Text(
            "Do you want to restore this transaction to your active list?",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.restore, color: Colors.white),
              label: const Text("Restore"),
              onPressed: () {
                Provider.of<TransactionProvider>(
                  context,
                  listen: false,
                ).restoreTransaction(id);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Transaction restored successfully! ♻️",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.blueAccent,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermanentDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Row(
            children: const [
              Icon(Icons.delete_forever, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                "Permanent Delete",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          content: const Text(
            "This will permanently delete the transaction. This action cannot be undone.",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text("Delete"),
              onPressed: () {
                Provider.of<TransactionProvider>(
                  context,
                  listen: false,
                ).permanentlyDeleteTransaction(id);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Transaction permanently deleted ❌"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final deletedList = provider.deletedTransactions;

        return RefreshIndicator(
          onRefresh: () async {
            await provider.refreshData();
          },
          child: Skeletonizer(
            enabled: provider.isLoading,
            child: (deletedList.isEmpty && !provider.isLoading)
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 200),
                      Center(
                        child: Text(
                          'No deleted transactions.\nYour history will appear here.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.isLoading ? 8 : deletedList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final txn = provider.isLoading
                          ? TransactionModel(
                              name: "Deleted Item Name",
                              category: "General",
                              amount: 0.0,
                              type: "Expense",
                              date: DateTime.now().toIso8601String(),
                            )
                          : deletedList[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  (txn.type == 'Income'
                                          ? Colors.green
                                          : Colors.red)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              txn.type == 'Income'
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: txn.type == 'Income'
                                  ? Colors.green
                                  : Colors.redAccent,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            txn.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                txn.category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                _formatDate(txn.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          trailing: provider.isLoading
                              ? null
                              : PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'restore') {
                                      _showRestoreDialog(context, txn.id!);
                                    } else if (value == 'delete') {
                                      _showPermanentDeleteDialog(
                                        context,
                                        txn.id!,
                                      );
                                    }
                                  },
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'restore',
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.restore,
                                              color: Colors.blue,
                                            ),
                                            title: Text('Restore'),
                                            contentPadding: EdgeInsets.zero,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                            ),
                                            title: Text('Delete Permanently'),
                                            contentPadding: EdgeInsets.zero,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                      ],
                                ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
