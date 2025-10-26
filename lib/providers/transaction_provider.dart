import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../db/db_helper.dart';

class TransactionProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<TransactionModel> _transactions = [];
  final List<TransactionModel> _deletedTransactions = [];

  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get deletedTransactions => _deletedTransactions;

  /// Load all transactions from DB
  Future<void> loadTransactions() async {
    try {
      _transactions = await _dbHelper.getTransactions();
      notifyListeners();
      debugPrint("Loaded ${_transactions.length} transactions from DB.");
    } catch (e) {
      debugPrint("Error loading transactions: $e");
    }
  }

  /// Add new transaction
  Future<void> addTransaction(TransactionModel txn) async {
    try {
      txn.amount = txn.amount.abs();
      if (txn.type != "Income" && txn.type != "Expense") {
        txn.type = "Expense";
      }

      await _dbHelper.insertTransaction(txn);
      await loadTransactions();
      debugPrint("Added transaction: ${txn.category}, ${txn.amount}, ${txn.type}");
    } catch (e) {
      debugPrint("Error adding transaction: $e");
    }
  }

  /// Delete transaction (move to history)
  Future<void> deleteTransaction(int id) async {
    try {
      final txn = _transactions.firstWhere((t) => t.id == id);
      _deletedTransactions.add(txn);
      await _dbHelper.deleteTransaction(id);
      await loadTransactions();
      notifyListeners();
      debugPrint("Deleted transaction id: $id");
    } catch (e) {
      debugPrint("Error deleting transaction: $e");
    }
  }

  /// Get total balance
  double getTotalBalance() {
    double total = 0;
    for (var t in _transactions) {
      total += t.type == "Income" ? t.amount : -t.amount;
    }
    return total;
  }
}
