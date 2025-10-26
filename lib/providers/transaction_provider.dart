import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../db/db_helper.dart';

class TransactionProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  List<TransactionModel> _transactions = [];
  List<TransactionModel> _deletedTransactions = [];

  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get deletedTransactions => _deletedTransactions;

  // ---------------------- LOAD ALL DATA ----------------------
  Future<void> loadTransactions() async {
    final activeList = await _dbHelper.getTransactions();
    final deletedList = await _dbHelper.getDeletedTransactions();

    _transactions = activeList;
    _deletedTransactions = deletedList;
    notifyListeners();
  }

  // ---------------------- ADD TRANSACTION ----------------------
  Future<void> addTransaction(TransactionModel txn) async {
    await _dbHelper.insertTransaction(txn);
    await loadTransactions();
  }

  // ---------------------- DELETE TRANSACTION ----------------------
  Future<void> deleteTransaction(int id) async {
    try {
      // Find the transaction first
      final txn = _transactions.firstWhere((t) => t.id == id);
      // Save it to deleted_transactions
      await _dbHelper.insertDeletedTransaction(txn);
      // Remove from active list
      await _dbHelper.deleteTransaction(id);
      // Reload all
      await loadTransactions();
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  // ---------------------- BALANCE ----------------------
  double getTotalBalance() {
    double total = 0;
    for (var t in _transactions) {
      total += t.type == "Income" ? t.amount : -t.amount;
    }
    return total;
  }
}
