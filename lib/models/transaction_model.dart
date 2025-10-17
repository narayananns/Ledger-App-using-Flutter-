class TransactionModel {
  int? id;
  String category;
  double amount;
  String type; // Income or Expense
  String date;
  bool isCompleted;

  TransactionModel({
    this.id,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'type': type,
      'date': date,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      type: map['type'],
      date: map['date'],
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
