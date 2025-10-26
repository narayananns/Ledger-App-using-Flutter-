class TransactionModel {
  int? id;
  String category;
  double amount;
  String type; // Income / Expense
  String date;

  TransactionModel({
    this.id,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'type': type,
      'date': date,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      type: map['type'],
      date: map['date'],
    );
  }
}
