import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<TransactionModel> _transactions = [];
  List<TransactionModel> _deletedTransactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get deletedTransactions => _deletedTransactions;

  bool get isLoading => _isLoading;

  String? _currentUserId;

  // Initialize with the current user
  Future<void> init(User? user) async {
    if (user?.uid == _currentUserId) return;

    _currentUserId = user?.uid;
    _transactions = [];
    _deletedTransactions = [];

    if (user == null) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    await _loadTransactions();
    await _loadDeletedTransactions();
  }

  Future<void> _loadTransactions() async {
    if (_currentUserId == null) return;
    try {
      _transactions = await _dbService.getTransactions(_currentUserId!);
    } catch (e) {
      debugPrint("Database Load Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDeletedTransactions() async {
    if (_currentUserId == null) return;
    try {
      _deletedTransactions = await _dbService.getDeletedTransactions(
        _currentUserId!,
      );
      notifyListeners();
    } catch (e) {
      debugPrint("Database Load Deleted Error: $e");
    }
  }

  // ---------------------- REFRESH ----------------------
  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    await _loadTransactions();
    await _loadDeletedTransactions();
  }

  // ---------------------- ADD TRANSACTION ----------------------
  Future<String?> addTransaction(TransactionModel txn) async {
    if (_currentUserId == null) return "User not logged in";

    try {
      _isLoading = true;
      notifyListeners();

      await _dbService.insertTransaction(_currentUserId!, txn);

      // Update local state immediately (Add to top)
      _transactions.insert(0, txn);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint("Add Transaction Error: $e");
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  // ---------------------- UPDATE TRANSACTION ----------------------
  Future<void> updateTransaction(TransactionModel txn) async {
    if (_currentUserId == null) return;

    try {
      await _dbService.updateTransaction(_currentUserId!, txn);

      final index = _transactions.indexWhere((t) => t.id == txn.id);
      if (index != -1) {
        _transactions[index] = txn;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Update Transaction Error: $e");
    }
  }

  // ---------------------- DELETE TRANSACTION ----------------------
  Future<void> deleteTransaction(String id) async {
    if (_currentUserId == null) return;

    try {
      await _dbService.deleteTransaction(id);

      // Remove from active list and add to deleted list
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        final txn = _transactions[index];
        _transactions.removeAt(index);
        _deletedTransactions.insert(0, txn);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  // ---------------------- RESTORE TRANSACTION ----------------------
  Future<void> restoreTransaction(String id) async {
    if (_currentUserId == null) return;

    try {
      await _dbService.restoreTransaction(id);

      // Remove from deleted list and add to active list
      final index = _deletedTransactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        final txn = _deletedTransactions[index];
        _deletedTransactions.removeAt(index);
        _transactions.insert(0, txn);

        // Sort active transactions by date descending
        _transactions.sort((a, b) {
          int dateComp = b.date.compareTo(a.date);
          if (dateComp != 0) return dateComp;
          // Tie-break with creation time if available, or name
          return 0; // Simple date sort
        });

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Restore error: $e");
    }
  }

  // Permanently Delete Transaction from History
  Future<void> permanentlyDeleteTransaction(String id) async {
    if (_currentUserId == null) return;

    try {
      await _dbService.permanentlyDeleteTransaction(id);
      _deletedTransactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Permanent Delete error: $e");
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
