import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirestoreService() {
    // Ensure persistence is enabled (default on mobile, but good practice to be aware)
    _db.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
  }

  // Collection Reference: users -> {userId} -> transactions
  CollectionReference<Map<String, dynamic>> _getTransactionsRef(String userId) {
    return _db.collection('users').doc(userId).collection('transactions');
  }

  // Collection Reference: users -> {userId} -> deleted_transactions (optional archive)
  CollectionReference<Map<String, dynamic>> _getDeletedTransactionsRef(String userId) {
    return _db.collection('users').doc(userId).collection('deleted_transactions');
  }

  // STREAM: Get Realtime Transactions
  Stream<List<TransactionModel>> getTransactionsStream(String userId) {
    return _getTransactionsRef(userId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // STREAM: Get Deleted Transactions
  Stream<List<TransactionModel>> getDeletedTransactionsStream(String userId) {
    return _getDeletedTransactionsRef(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // ADD
  Future<void> addTransaction(String userId, TransactionModel txn) async {
    await _getTransactionsRef(userId).add(txn.toMap());
  }

  // UPDATE
  Future<void> updateTransaction(String userId, TransactionModel txn) async {
    if (txn.id == null) return;
    await _getTransactionsRef(userId).doc(txn.id).update(txn.toMap());
  }

  // DELETE (Move to deleted_transactions optional, or just delete)
  Future<void> deleteTransaction(String userId, TransactionModel txn) async {
    if (txn.id == null) return;
    
    // Optional: Archive before delete
    await _getDeletedTransactionsRef(userId).add(txn.toMap());

    // Delete
    await _getTransactionsRef(userId).doc(txn.id).delete();
  }
}
