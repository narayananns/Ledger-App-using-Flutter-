import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../widgets/transaction/transaction_form.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      child: Scaffold(
        backgroundColor: Colors.transparent, // Match original background
        appBar: AppBar(
          title: const Text(
            'Add Transaction',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF1A73E8),
          centerTitle: true,
          elevation: 0,
        ),
        body: TransactionForm(
          submitButtonText: 'Save Transaction',
          onSubmit: (transaction) async {
            // Show persistent loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) =>
                  const Center(child: CircularProgressIndicator()),
            );

            final provider = Provider.of<TransactionProvider>(
              context,
              listen: false,
            );

            try {
              String? error = await provider.addTransaction(transaction);

              // Close loading dialog
              if (context.mounted) Navigator.pop(context);

              if (error == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Transaction added successfully!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  Navigator.pop(context);
                }
              } else {
                if (context.mounted) {
                  // Show detailed error in alert dialog instead of snackbar for better visibility
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Error Adding Transaction"),
                      content: Text(error), // Show specific Firestore error
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              }
            } catch (e) {
              // Close loading dialog if still open
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              debugPrint("UI Logic Error: $e");
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('An unexpected error occurred.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
