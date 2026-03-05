import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String? id;
  String? userId; // Added userId for better data usage
  String name;
  String category;
  double amount;
  String type; // Income / Expense
  String date;
  String description;
  bool isSplit;
  int splitCount;
  double splitAmount;
  DateTime? createdAt; // Added createdAt

  TransactionModel({
    this.id,
    this.userId,
    required this.name,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    this.description = '',
    this.isSplit = false,
    this.splitCount = 1,
    this.splitAmount = 0.0,
    this.createdAt,
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
      'id': id,
      'userId': userId,
      'name': name,
      'category': category,
      'amount': amount,
      'type': type,
      'date': date,
      'description': description,
      'isSplit': isSplit,
      'splitCount': splitCount,
      'splitAmount': splitAmount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? created;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        created = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        created = DateTime.tryParse(map['createdAt']);
      }
    }

    return TransactionModel(
      id: docId,
      userId: map['userId'] as String?,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Others',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'Expense',
      date: map['date'] ?? DateTime.now().toString().split(' ')[0],
      description: map['description'] ?? '',
      isSplit: map['isSplit'] ?? false,
      splitCount: map['splitCount'] ?? 1,
      splitAmount: (map['splitAmount'] ?? map['amount'] ?? 0).toDouble(),
      createdAt: created,
    );
  }
}
