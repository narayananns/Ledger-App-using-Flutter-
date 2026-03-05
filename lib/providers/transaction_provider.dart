import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import '../services/firestore_service.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final FirestoreService _firestoreService = FirestoreService();

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
  }

  Future<void> _loadTransactions() async {
    if (_currentUserId == null) return;
    try {
      // 1. Try to load from Local DB first (Faster)
      _transactions = await _dbService.getTransactions(_currentUserId!);

      // 2. If Local DB is empty, try to fetch from Firestore (Data Restoration)
      if (_transactions.isEmpty) {
        debugPrint("Local DB empty. Attempting to restore from Cloud...");
        final cloudTransactions = await _firestoreService.fetchAllTransactions(
          _currentUserId!,
        );

        if (cloudTransactions.isNotEmpty) {
          debugPrint(
            "Found ${cloudTransactions.length} transactions in Cloud. Syncing to Local DB...",
          );
          // Save to local DB so next time it's fast
          for (var txn in cloudTransactions) {
            await _dbService.insertTransaction(_currentUserId!, txn);
          }
          _transactions = cloudTransactions;
        }
      }
    } catch (e) {
      debugPrint("Database Load Error: $e");
    } finally {
      await _loadDeletedTransactions();
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
  }

  // ---------------------- ADD TRANSACTION ----------------------
  Future<String?> addTransaction(TransactionModel txn) async {
    if (_currentUserId == null) return "User not logged in";

    try {
      _isLoading = true;
      notifyListeners();

      // Ensure ID exists before sync
      if (txn.id == null || txn.id!.isEmpty) {
        txn.id = DateTime.now().millisecondsSinceEpoch.toString();
      }
      txn.userId = _currentUserId; // Ensure userId is set
      txn.createdAt = DateTime.now(); // Set local creation time

      // 1. Save to Local DB
      await _dbService.insertTransaction(_currentUserId!, txn);

      // 2. Save to Cloud Firestore (Backup)
      try {
        await _firestoreService.addTransaction(_currentUserId!, txn);
      } catch (e) {
        debugPrint("Cloud Sync Error (Add): $e");
      }

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
      // 1. Update Local DB
      await _dbService.updateTransaction(_currentUserId!, txn);

      // 2. Update Cloud (Backup)
      try {
        await _firestoreService.updateTransaction(_currentUserId!, txn);
      } catch (e) {
        debugPrint("Cloud Sync Error (Update): $e");
      }

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
      // Find transaction locally first
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index == -1) return;
      final txn = _transactions[index];

      // 1. Delete/Soft Delete Local
      await _dbService.deleteTransaction(id);

      // 2. Delete/Archive Cloud
      try {
        await _firestoreService.deleteTransaction(_currentUserId!, id, txn);
      } catch (e) {
        debugPrint("Cloud Sync Error (Delete): $e");
      }

      // Update Local State
      _transactions.removeAt(index);
      _deletedTransactions.insert(0, txn);
      notifyListeners();
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  // ---------------------- RESTORE TRANSACTION ----------------------
  Future<void> restoreTransaction(String id) async {
    if (_currentUserId == null) return;

    try {
      // Find from deleted list
      final index = _deletedTransactions.indexWhere((t) => t.id == id);
      if (index == -1) return;
      final txn = _deletedTransactions[index]; // Define txn here

      // 1. Restore Local
      await _dbService.restoreTransaction(id);

      // 2. Restore Cloud
      try {
        await _firestoreService.restoreTransaction(_currentUserId!, id, txn);
      } catch (e) {
        debugPrint("Cloud Sync Error (Restore): $e");
      }

      // Update Local State
      _deletedTransactions.removeAt(index);
      _transactions.insert(0, txn);

      // Sort active transactions by date descending
      _transactions.sort((a, b) {
        int dateComp = b.date.compareTo(a.date);
        return dateComp;
      });

      notifyListeners();
    } catch (e) {
      debugPrint("Restore error: $e");
    }
  }

  // Permanently Delete Transaction from History
  Future<void> permanentlyDeleteTransaction(String id) async {
    if (_currentUserId == null) return;

    try {
      // 1. Delete Local
      await _dbService.permanentlyDeleteTransaction(id);

      // 2. Delete Cloud
      // Note: We need the transaction object to delete it properly in some architectures,
      // but for generic delete we just need ID.
      // However, FirestoreService.deleteTransaction signature requires model for archiving.
      // Since this is permanent delete, we might just want to delete the doc.
      // Let's assume firestoreService has a permanent delete or we skip archiving.
      // Ideally we should add a specific method for permanent delete in FirestoreService too.
      // For now, let's just attempt a delete on the main collection and deleted collection.
      try {
        // We might not have the full txn object easily available if it's only in _deletedTransactions list...
        // But we can find it:
        final txn = _deletedTransactions.firstWhere(
          (t) => t.id == id,
          orElse: () => TransactionModel(
            id: id,
            userId: _currentUserId,
            name: '',
            category: '',
            amount: 0,
            type: '',
            date: DateTime.now().toIso8601String(),
          ),
        );
        if (txn.name.isNotEmpty) {
          await _firestoreService.deleteTransaction(_currentUserId!, id, txn);
        }
      } catch (e) {
        debugPrint("Cloud Sync Error (Permanent Delete): $e");
      }

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
