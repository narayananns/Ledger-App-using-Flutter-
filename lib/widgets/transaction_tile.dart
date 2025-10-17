// import 'package:flutter/material.dart';
// import '../models/transaction_model.dart';
// import 'package:intl/intl.dart';


// class TransactionTile extends StatelessWidget {
// final TransactionModel transaction;
// final VoidCallback onEdit;
// final VoidCallback onDelete;


// const TransactionTile({
// Key? key,
// required this.transaction,
// required this.onEdit,
// required this.onDelete,
// }) : super(key: key);


// @override
// Widget build(BuildContext context) {
// final date = DateTime.parse(transaction.date);
// final formatted = DateFormat('yyyy-MM-dd').format(date);
// final isIncome = transaction.type == 'Income';


// return Card(
// child: ListTile(
// leading: CircleAvatar(
// child: Text(isIncome ? 'I' : 'E'),
// ),
// title: Text('${transaction.category} - ${transaction.note ?? ''}'),
// subtitle: Text(formatted),
// trailing: Column(
// mainAxisAlignment: MainAxisAlignment.center,
// crossAxisAlignment: CrossAxisAlignment.end,
// children: [
// Text((isIncome ? '+' : '-') + transaction.amount.toStringAsFixed(2)),
// Row(
// mainAxisSize: MainAxisSize.min,
// children: [
// IconButton(icon: Icon(Icons.edit, size: 18), onPressed: onEdit),
// IconButton(icon: Icon(Icons.delete, size: 18), onPressed: onDelete),
// ],
// )
// ],
// ),
// ),
// );
// }
// }