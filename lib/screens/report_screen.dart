import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';

class ReportScreen extends StatelessWidget {
  final List<TransactionModel> transactions;

  const ReportScreen({Key? key, required this.transactions}) : super(key: key);

  // Group total amounts by category (income positive, expense negative)
  Map<String, double> _groupByCategory() {
    final Map<String, double> map = {};
    for (var t in transactions) {
      map[t.category] =
          (map[t.category] ?? 0) + t.amount * (t.type == "Income" ? 1 : -1);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final data = _groupByCategory();
    final entries = data.entries.where((e) => e.value != 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: entries.isEmpty
          ? const Center(child: Text('No data available'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Category-wise (Total Amount in charts)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    " Green -> Income.",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.greenAccent,
                      backgroundColor: Colors.black54
                    ),
                  ),
                  SizedBox(height: 20,),
                  Text(
                    " Red -> Expense.",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.red,
                      backgroundColor: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: entries.map((e) {
                          final isPositive = e.value >= 0;
                          return PieChartSectionData(
                            color: isPositive
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            value: e.value.abs(),
                            title: '${e.key}\n${e.value.toStringAsFixed(2)}',
                            radius: 90,
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
