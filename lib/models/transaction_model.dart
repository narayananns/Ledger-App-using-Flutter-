import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String? id;
  String name;
  String category;
  double amount;
  String type; // Income / Expense
  String date;
  String description;
  bool isSplit;
  int splitCount;
  double splitAmount;

  TransactionModel({
    this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    this.description = '',
    this.isSplit = false,
    this.splitCount = 1,
    this.splitAmount = 0.0,
  }) {
    // Calculate split amount if split is enabled
    if (isSplit && splitCount > 0) {
      splitAmount = amount / splitCount;
    } else {
      splitAmount = amount;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'amount': amount,
      'type': type,
      'date': date,
      'description': description,
      'isSplit': isSplit, // Firestore supports bool
      'splitCount': splitCount,
      'splitAmount': splitAmount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    return TransactionModel(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Others',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'Expense',
      date: map['date'] ?? DateTime.now().toString().split(' ')[0],
      description: map['description'] ?? '',
      isSplit: map['isSplit'] ?? false,
      splitCount: map['splitCount'] ?? 1,
      splitAmount: (map['splitAmount'] ?? map['amount'] ?? 0).toDouble(),
    );
  }
}
