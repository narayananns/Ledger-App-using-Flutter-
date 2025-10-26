import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';
import 'report_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showDeleteDialog(BuildContext context, int id) {
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
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                "Transaction Action",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to delete this transaction?",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text(
                "Delete",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Provider.of<TransactionProvider>(
                  context,
                  listen: false,
                ).deleteTransaction(id);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Transaction deleted successfully ❌",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    backgroundColor: Colors.white70,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHome(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        final transactions = provider.transactions;
        final totalBalance = provider.getTotalBalance();

        if (transactions.isEmpty) {
          return const Center(
            child: Text(
              'No transactions yet. Tap "Add Transaction" to add one.',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.grey],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Text(
                'Total Balance: ₹${totalBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    elevation: 3,
                    shadowColor: Colors.grey.shade200,
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: t.type == "Income"
                            ? Colors.green
                            : Colors.redAccent,
                        child: Icon(
                          t.type == "Income"
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        t.category,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        _formatDate(t.date),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${t.type == "Income" ? "+" : "-"}₹${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: t.type == "Income"
                                  ? Colors.green
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              _showDeleteDialog(context, t.id!);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [_buildHome(context), const HistoryScreen()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger Book'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        actions: [
          Consumer<TransactionProvider>(
            builder: (context, provider, _) => IconButton(
              icon: const Icon(Icons.pie_chart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReportScreen(transactions: provider.transactions),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
      // Positioned ElevatedButton above bottom navigation bar on right side
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 10, right: 10),
              child: Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddTransactionScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add Transaction",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat as FloatingActionButtonLocation?,
    );
  }
}
