import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../providers/transaction_provider.dart';
import '../widgets/common/search_bar_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

        final filteredList = deletedList.where((t) {
          final query = _searchQuery.toLowerCase();
          return t.name.toLowerCase().contains(query) ||
              t.category.toLowerCase().contains(query);
        }).toList();

        // Sort for grouping
        filteredList.sort((a, b) => b.date.compareTo(a.date));

        return RefreshIndicator(
          onRefresh: () async {
            await provider.refreshData();
          },
          child: Skeletonizer(
            enabled: provider.isLoading,
            child: Column(
              children: [
                SearchBarWidget(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                Expanded(
                  child: (deletedList.isEmpty && !provider.isLoading)
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
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
                      : (filteredList.isEmpty && !provider.isLoading)
                      ? ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: const [
                            SizedBox(height: 200),
                            Center(
                              child: Text(
                                "No results found",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.all(12),
                          itemCount: provider.isLoading
                              ? 8
                              : filteredList.length,
                          itemBuilder: (context, index) {
                            if (provider.isLoading) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const ListTile(
                                  title: Text("Loading Item"),
                                  subtitle: Text("Category"),
                                ),
                              );
                            }

                            final txn = filteredList[index];
                            bool showHeader = false;

                            if (index == 0) {
                              showHeader = true;
                            } else {
                              try {
                                final prevT = filteredList[index - 1];
                                final prevDate = DateTime.parse(prevT.date);
                                final currDate = DateTime.parse(txn.date);
                                if (prevDate.year != currDate.year ||
                                    prevDate.month != currDate.month) {
                                  showHeader = true;
                                }
                              } catch (_) {
                                showHeader = true;
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showHeader)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      4,
                                      16,
                                      4,
                                      8,
                                    ),
                                    child: Text(
                                      DateFormat(
                                        'MMM yyyy',
                                      ).format(DateTime.parse(txn.date)),
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                _showRestoreDialog(
                                                  context,
                                                  txn.id!,
                                                );
                                              } else if (value == 'delete') {
                                                _showPermanentDeleteDialog(
                                                  context,
                                                  txn.id!,
                                                );
                                              }
                                            },
                                            itemBuilder:
                                                (
                                                  BuildContext context,
                                                ) => <PopupMenuEntry<String>>[
                                                  const PopupMenuItem<String>(
                                                    value: 'restore',
                                                    child: ListTile(
                                                      leading: Icon(
                                                        Icons.restore,
                                                        color: Colors.blue,
                                                      ),
                                                      title: Text('Restore'),
                                                      contentPadding:
                                                          EdgeInsets.zero,
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
                                                      title: Text(
                                                        'Delete Permanently',
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                    ),
                                                  ),
                                                ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
