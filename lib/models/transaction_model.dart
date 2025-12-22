class TransactionModel {
  int? id;
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
      'id': id,
      'name': name,
      'category': category,
      'amount': amount,
      'type': type,
      'date': date,
      'description': description,
      'isSplit': isSplit ? 1 : 0,
      'splitCount': splitCount,
      'splitAmount': splitAmount,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      name: map['name'] ?? '',
      category: map['category'],
      amount: map['amount'],
      type: map['type'],
      date: map['date'],
      description: map['description'] ?? '',
      isSplit: (map['isSplit'] ?? 0) == 1,
      splitCount: map['splitCount'] ?? 1,
      splitAmount: map['splitAmount'] ?? map['amount'],
    );
  }
}
