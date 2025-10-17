import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../db/db_helper.dart';

class TransactionProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<TransactionModel> _transactions = [];

  List<TransactionModel> get transactions => _transactions;

  /// Load all transactions from the database
  Future<void> loadTransactions() async {
    try {
      _transactions = await _dbHelper.getTransactions();
      notifyListeners(); // ✅ Update UI
      debugPrint("Loaded ${_transactions.length} transactions from DB.");
    } catch (e) {
      debugPrint("Error loading transactions: $e");
    }
  }

  /// Add a new transaction and reload
  Future<void> addTransaction(TransactionModel txn) async {
    try {
      // Ensure the amount is positive
      txn.amount = txn.amount.abs();

      // Normalize type string
      if (txn.type != "Income" && txn.type != "Expense") {
        txn.type = "Expense"; // default fallback
      }

      await _dbHelper.insertTransaction(txn);
      await loadTransactions(); // reload to update UI
      debugPrint(
        "Added transaction: ${txn.category}, ${txn.amount}, ${txn.type}",
      );
    } catch (e) {
      debugPrint("Error adding transaction: $e");
    }
  }

  /// Delete a transaction by id
  Future<void> deleteTransaction(int id) async {
    try {
      await _dbHelper.deleteTransaction(id);
      await loadTransactions(); // reload to update UI
      debugPrint("Deleted transaction id: $id");
    } catch (e) {
      debugPrint("Error deleting transaction: $e");
    }
  }

  /// Calculate total balance
  double getTotalBalance() {
    double total = 0;
    for (var t in _transactions) {
      if (t.type == "Income") {
        total += t.amount;
      } else {
        total -= t.amount;
      }
    }
    return total;
  }
}
