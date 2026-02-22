import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import '../services/auth_service.dart';
import '../widgets/home/total_balance_card.dart';
import '../widgets/home/transaction_list_item.dart';
import '../widgets/common/carousel_loader.dart';
import '../widgets/common/search_bar_widget.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(BuildContext context, String id) {
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
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
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
              icon: const Icon(Icons.delete_forever, color: Colors.white),
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
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Logout"),
          content: const Text("Are you sure you want to sign out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
                Provider.of<AuthService>(context, listen: false).signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text("Logout"),
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

        final filteredTransactions = transactions.where((t) {
          final query = _searchQuery.toLowerCase();
          return t.name.toLowerCase().contains(query) ||
              t.category.toLowerCase().contains(query);
        }).toList();

        // Ensure sorted by date for grouping
        filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

        return RefreshIndicator(
          onRefresh: () => provider.refreshData(),
          color: const Color(0xFF1A73E8),
          child: Skeletonizer(
            enabled: provider.isLoading,
            child: Column(
              children: [
                TotalBalanceCard(
                  totalBalance: provider.isLoading ? 5430.50 : totalBalance,
                ),
                SearchBarWidget(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                Expanded(
                  child: (transactions.isEmpty && !provider.isLoading)
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: const [
                            SizedBox(height: 50),
                            CarouselLoader(
                              message: "Tap '+' to add your first transaction",
                            ),
                          ],
                        )
                      : (filteredTransactions.isEmpty && !provider.isLoading)
                      ? ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: const [
                            SizedBox(height: 50),
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
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: provider.isLoading
                              ? 8
                              : filteredTransactions.length,
                          itemBuilder: (context, index) {
                            if (provider.isLoading) {
                              return Column(
                                children: [
                                  TransactionListItem(
                                    transaction: TransactionModel(
                                      name: "Grocery Shopping",
                                      category: "Food & Drinks",
                                      amount: 120.0,
                                      type: "Expense",
                                      date: DateTime.now().toIso8601String(),
                                    ),
                                    onDelete: () {},
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              );
                            }

                            final t = filteredTransactions[index];
                            bool showHeader = false;

                            if (index == 0) {
                              showHeader = true;
                            } else {
                              try {
                                final prevT = filteredTransactions[index - 1];
                                final prevDate = DateTime.parse(prevT.date);
                                final currDate = DateTime.parse(t.date);
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
                                      16,
                                      24,
                                      16,
                                      8,
                                    ),
                                    child: Text(
                                      DateFormat(
                                        'MMM yyyy',
                                      ).format(DateTime.parse(t.date)),
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                TransactionListItem(
                                  transaction: t,
                                  onDelete: () =>
                                      _showDeleteDialog(context, t.id!),
                                ),
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

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHome(context),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Ledger Book'
              : _selectedIndex == 1
              ? 'History'
              : 'Profile',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A73E8),
        elevation: 0,
        actions: _selectedIndex == 2
            ? [] // Hide actions on Profile screen
            : [
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert), // 3 dots settings icon
                  onSelected: (value) {
                    switch (value) {
                      case 'invite':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Invite Friends functionality coming soon!',
                            ),
                          ),
                        );
                        break;
                      case 'rate':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Rate App functionality coming soon!',
                            ),
                          ),
                        );
                        break;
                      case 'contact':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Contact support: support@ledgerbook.com',
                            ),
                          ),
                        );
                        break;
                      case 'terms':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Terms & Conditions coming soon!'),
                          ),
                        );
                        break;
                      case 'privacy':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Privacy Policy coming soon!'),
                          ),
                        );
                        break;
                      case 'about':
                        showAboutDialog(
                          context: context,
                          applicationName: 'Ledger Book',
                          applicationVersion: '1.0.0',
                          applicationLegalese:
                              '© 2026 Ledger Book. All rights reserved.',
                          applicationIcon: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 40,
                            color: Color(0xFF1A73E8),
                          ),
                        );
                        break;
                      case 'logout':
                        _showLogoutDialog(context);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'invite',
                          child: ListTile(
                            leading: Icon(
                              Icons.person_add_alt_1,
                              color: Colors.blue,
                            ),
                            title: Text('Invite Friends'),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'rate',
                          child: ListTile(
                            leading: Icon(
                              Icons.star_rate_rounded,
                              color: Colors.amber,
                            ),
                            title: Text('Rate App'),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'contact',
                          child: ListTile(
                            leading: Icon(
                              Icons.headset_mic_rounded,
                              color: Colors.green,
                            ),
                            title: Text('Contact Us'),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'terms',
                          child: ListTile(
                            leading: Icon(
                              Icons.gavel_rounded,
                              color: Colors.grey,
                            ),
                            title: Text('Terms & Conditions'),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'privacy',
                          child: ListTile(
                            leading: Icon(
                              Icons.privacy_tip_rounded,
                              color: Colors.grey,
                            ),
                            title: Text('Privacy Policy'),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'about',
                          child: ListTile(
                            leading: Icon(
                              Icons.info_outline_rounded,
                              color: Colors.blueGrey,
                            ),
                            title: Text('About'),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: ListTile(
                            leading: Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                            ),
                            title: Text(
                              'Logout',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                ),
              ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Consumer<TransactionProvider>(
          builder: (context, provider, child) {
            // Permanently use the nice gradient for all screens for consistency
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE3F2FD), // Light Blue
                    Color(0xFFF3E5F5), // Light Purple
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: screens[_selectedIndex],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1A73E8),
        unselectedItemColor: Colors.grey,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: "History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF1A73E8),
              elevation: 6,
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
              label: const Text(
                "Add Transaction",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
