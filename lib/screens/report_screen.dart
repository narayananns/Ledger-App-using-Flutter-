import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class ReportScreen extends StatefulWidget {
  final List<TransactionModel> transactions;

  const ReportScreen({super.key, required this.transactions});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedChartType = 'Pie Chart (Category)';
  // Initialize with current month
  DateTime _selectedDate = DateTime.now();

  final List<String> _chartTypes = [
    'Pie Chart (Category)',
    'Bar Chart (Category)',
    'Line Chart (Trend)',
    'Stacked Bar (Daily)',
  ];

  /// Helper to map category names to Icons
  IconData _getCategoryIcon(String category) {
    switch (category) {
      // Income
      case 'Salary':
        return Icons.attach_money;
      case 'Freelance':
        return Icons.computer;
      case 'Investment':
        return Icons.trending_up;
      case 'Business':
        return Icons.business_center;
      case 'Gift':
        return Icons.card_giftcard;
      case 'Bonus':
        return Icons.star_border;
      case 'Refund':
        return Icons.replay;

      // Expense
      case 'Food':
        return Icons.restaurant;
      case 'Petrol':
        return Icons.local_gas_station;
      case 'Transportation':
        return Icons.commute;
      case 'House Rent':
        return Icons.home;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills & Utilities':
        return Icons.receipt_long;
      case 'Entertainment':
        return Icons.movie;
      case 'Healthcare':
        return Icons.medical_services;
      case 'Education':
        return Icons.school;
      case 'Travel':
        return Icons.flight;
      case 'Groceries':
        return Icons.local_grocery_store;
      case 'Mobile Recharge':
        return Icons.phone_android;
      case 'Internet':
        return Icons.wifi;

      default:
        return Icons.category;
    }
  }

  /// Filter transactions for the selected month
  List<TransactionModel> get _filteredTransactions {
    return widget.transactions.where((t) {
      final date = DateTime.parse(t.date);
      return date.year == _selectedDate.year &&
          date.month == _selectedDate.month;
    }).toList();
  }

  /// Group by Category -> Net Amount
  Map<String, double> _groupByCategory() {
    final Map<String, double> map = {};
    for (var t in _filteredTransactions) {
      double signedAmount = t.amount * (t.type == "Income" ? 1 : -1);
      map[t.category] = (map[t.category] ?? 0) + signedAmount;
    }
    return map;
  }

  /// Group by Date -> {Income: val, Expense: val}
  Map<String, Map<String, double>> _groupByDate() {
    final sortedTxns = List.of(_filteredTransactions);
    sortedTxns.sort((a, b) => a.date.compareTo(b.date));

    final Map<String, Map<String, double>> map = {};

    for (var t in sortedTxns) {
      DateTime dt = DateTime.parse(t.date);
      String dayKey = DateFormat('yyyy-MM-dd').format(dt);

      map.putIfAbsent(dayKey, () => {'Income': 0.0, 'Expense': 0.0});

      if (t.type == "Income") {
        map[dayKey]!['Income'] = (map[dayKey]!['Income'] ?? 0) + t.amount;
      } else {
        map[dayKey]!['Expense'] = (map[dayKey]!['Expense'] ?? 0) + t.amount;
      }
    }
    return map;
  }

  List<FlSpot> _getLineChartSpots() {
    final grouped = _groupByDate();
    final sortedKeys = grouped.keys.toList()..sort();

    List<FlSpot> spots = [];

    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final income = grouped[key]!['Income'] ?? 0;
      final expense = grouped[key]!['Expense'] ?? 0;
      final net = income - expense;
      spots.add(FlSpot(i.toDouble(), net));
    }
    return spots;
  }

  Widget _buildPieChart(BuildContext context) {
    final data = _groupByCategory();
    final entries = data.entries.where((e) => e.value != 0).toList();

    if (entries.isEmpty) {
      return const Center(child: Text("No data for Pie Chart"));
    }

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: entries.map((e) {
                final isPositive = e.value >= 0;
                return PieChartSectionData(
                  color: isPositive
                      ? Colors.green.shade400
                      : Colors.red.shade400,
                  value: e.value.abs(),
                  title: '${e.key}\n${e.value.abs().toStringAsFixed(0)}',
                  radius: 100,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  badgeWidget: _Badge(
                    _getCategoryIcon(e.key),
                    size: 40,
                    borderColor: isPositive ? Colors.green : Colors.red,
                  ),
                  badgePositionPercentageOffset: .98,
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Green: Income | Red: Expense",
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final data = _groupByCategory();
    final entries = data.entries.where((e) => e.value != 0).toList();
    if (entries.isEmpty) {
      return const Center(child: Text("No data for Bar Chart"));
    }

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${entries[groupIndex].key}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: rod.toY.toStringAsFixed(2),
                    style: TextStyle(color: rod.color),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < entries.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      entries[value.toInt()].key.length > 5
                          ? '${entries[value.toInt()].key.substring(0, 5)}...'
                          : entries[value.toInt()].key,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        barGroups: entries.asMap().entries.map((e) {
          final isPositive = e.value.value >= 0;
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                color: isPositive ? Colors.green : Colors.red,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final spots = _getLineChartSpots();
    final grouped = _groupByDate();
    final sortedKeys = grouped.keys.toList()..sort();

    if (spots.isEmpty) {
      return const Center(child: Text("No data for Line Chart"));
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.blueAccent,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final dateStr = sortedKeys[spot.x.toInt()];
                return LineTooltipItem(
                  '$dateStr\n${spot.y.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                if (idx >= 0 && idx < sortedKeys.length) {
                  if (sortedKeys.length > 7 &&
                      idx % (sortedKeys.length ~/ 5) != 0) {
                    return const SizedBox();
                  }
                  final date = DateTime.parse(sortedKeys[idx]);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedBarChart(BuildContext context) {
    final grouped = _groupByDate();
    final sortedKeys = grouped.keys.toList()..sort();

    if (sortedKeys.isEmpty) {
      return const Center(child: Text("No data for Stacked Chart"));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                if (idx >= 0 && idx < sortedKeys.length) {
                  if (sortedKeys.length > 7 &&
                      idx % (sortedKeys.length ~/ 5) != 0) {
                    return const SizedBox();
                  }
                  final date = DateTime.parse(sortedKeys[idx]);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: sortedKeys.asMap().entries.map((e) {
          int index = e.key;
          String dateKey = e.value;
          double income = grouped[dateKey]!['Income']!;
          double expense = grouped[dateKey]!['Expense']!;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: income, color: Colors.green, width: 12),
              BarChartRodData(toY: expense, color: Colors.red, width: 12),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFE3F2FD), // Light Blue
            Color(0xFFF3E5F5), // Light Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Professional Reports',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF1A73E8),
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month - 1,
                        );
                      });
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedChartType,
                    icon: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF1A73E8),
                    ),
                    isExpanded: true,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    items: _chartTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedChartType = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _selectedChartType == 'Pie Chart (Category)'
                      ? _buildPieChart(context)
                      : _selectedChartType == 'Bar Chart (Category)'
                      ? _buildBarChart(context)
                      : _selectedChartType == 'Line Chart (Trend)'
                      ? _buildLineChart(context)
                      : _buildStackedBarChart(context),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  _selectedChartType == 'Line Chart (Trend)'
                      ? 'Showing Daily Net Flow (Income - Expense)'
                      : _selectedChartType == 'Stacked Bar (Daily)'
                      ? 'Comparison of Income vs Expense per Day'
                      : 'Distribution by Category',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color borderColor;

  const _Badge(this.icon, {required this.size, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.0),
      child: Center(
        child: Icon(icon, size: size * 0.6, color: borderColor),
      ),
    );
  }
}
