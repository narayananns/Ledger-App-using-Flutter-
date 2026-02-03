import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction_model.dart';
import 'transaction_detail_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

enum AnalysisFilter { day, month, year, range }

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalysisFilter _selectedFilter = AnalysisFilter.month;
  DateTime _focusedDate = DateTime.now();
  DateTimeRange? _customDateRange;

  // For Top Spends List
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    // Default range is this month
  }

  // --- Date Helpers ---

  void _previousPeriod() {
    setState(() {
      switch (_selectedFilter) {
        case AnalysisFilter.day:
          _focusedDate = _focusedDate.subtract(const Duration(days: 1));
          break;
        case AnalysisFilter.month:
          _focusedDate = DateTime(
            _focusedDate.year,
            _focusedDate.month - 1,
            _focusedDate.day,
          );
          break;
        case AnalysisFilter.year:
          _focusedDate = DateTime(
            _focusedDate.year - 1,
            _focusedDate.month,
            _focusedDate.day,
          );
          break;
        case AnalysisFilter.range:
          break;
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      switch (_selectedFilter) {
        case AnalysisFilter.day:
          _focusedDate = _focusedDate.add(const Duration(days: 1));
          break;
        case AnalysisFilter.month:
          _focusedDate = DateTime(
            _focusedDate.year,
            _focusedDate.month + 1,
            _focusedDate.day,
          );
          break;
        case AnalysisFilter.year:
          _focusedDate = DateTime(
            _focusedDate.year + 1,
            _focusedDate.month,
            _focusedDate.day,
          );
          break;
        case AnalysisFilter.range:
          break;
      }
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange:
          _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF1A73E8),
            colorScheme: const ColorScheme.light(primary: Color(0xFF1A73E8)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFilter = AnalysisFilter.range;
        _customDateRange = picked;
      });
    }
  }

  // --- Filtering Logic ---

  List<TransactionModel> _getFilteredTransactions(
    List<TransactionModel> allTransactions,
  ) {
    return allTransactions.where((t) {
      try {
        DateTime tDate = DateTime.parse(t.date);
        switch (_selectedFilter) {
          case AnalysisFilter.day:
            return tDate.year == _focusedDate.year &&
                tDate.month == _focusedDate.month &&
                tDate.day == _focusedDate.day;
          case AnalysisFilter.month:
            return tDate.year == _focusedDate.year &&
                tDate.month == _focusedDate.month;
          case AnalysisFilter.year:
            return tDate.year == _focusedDate.year;
          case AnalysisFilter.range:
            if (_customDateRange == null) return true;
            return tDate.isAfter(
                  _customDateRange!.start.subtract(const Duration(seconds: 1)),
                ) &&
                tDate.isBefore(
                  _customDateRange!.end.add(const Duration(days: 1)),
                );
        }
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // --- Chart Data Preparation ---

  List<BarChartGroupData> _getChartGroups(List<TransactionModel> transactions) {
    Map<int, Map<String, double>> data = {};

    // Grouping
    for (var t in transactions) {
      try {
        DateTime d = DateTime.parse(t.date);
        int index = 0;

        switch (_selectedFilter) {
          case AnalysisFilter.day:
            // Only one group really, or maybe hourly if we had time?
            // Let's do category breakdown for day in chart? Or just single bar?
            // Maybe Income vs Expense bars.
            index = 0;
            break;
          case AnalysisFilter.month:
            index = d.day; // 1..31
            break;
          case AnalysisFilter.year:
            index = d.month; // 1..12
            break;
          case AnalysisFilter.range:
            // Bin by day relative to start? Too complex for bar chart if long range.
            // Let's just do daily for range.
            index = d.difference(_customDateRange!.start).inDays;

            // Limit bars if too many?
            break;
        }

        data.putIfAbsent(index, () => {"Income": 0, "Expense": 0});
        if (t.type == "Income") {
          data[index]!["Income"] = (data[index]!["Income"] ?? 0) + t.amount;
        } else {
          data[index]!["Expense"] = (data[index]!["Expense"] ?? 0) + t.amount;
        }
      } catch (_) {}
    }

    List<BarChartGroupData> groups = [];
    final sortedKeys = data.keys.toList()..sort();

    for (var key in sortedKeys) {
      groups.add(
        BarChartGroupData(
          x: key,
          barRods: [
            BarChartRodData(
              toY: data[key]!["Income"]!,
              color: Colors.greenAccent.shade700,
              width: 8, // Thinner bars
              borderRadius: BorderRadius.circular(2),
            ),
            BarChartRodData(
              toY: data[key]!["Expense"]!,
              color: Colors.redAccent.shade400,
              width: 8,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final allTransactions = provider.transactions;
    final isLoading = provider.isLoading;

    List<TransactionModel> filteredTransactions;

    if (isLoading) {
      filteredTransactions = List.generate(
        5,
        (index) => TransactionModel(
          name: "Loading Data",
          category: "General",
          amount: 1000.0 * (index + 1),
          type: index % 2 == 0 ? "Income" : "Expense",
          date: _focusedDate.toIso8601String(),
        ),
      );
    } else {
      filteredTransactions = _getFilteredTransactions(allTransactions);
    }

    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in filteredTransactions) {
      if (t.type == "Income") {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    // Sort for "Top Spends"
    List<TransactionModel> sortedTransactions = List.from(filteredTransactions);
    sortedTransactions.sort(
      (a, b) => _sortDescending
          ? b.amount.compareTo(a.amount)
          : a.amount.compareTo(b.amount),
    );

    return Container(
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
            'Analytics Dashboard',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF1A73E8),
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: () async => await provider.refreshData(),
          child: Skeletonizer(
            enabled: isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Filter Tabs ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFilterTab("Day", AnalysisFilter.day),
                        _buildFilterTab("Month", AnalysisFilter.month),
                        _buildFilterTab("Year", AnalysisFilter.year),
                        _buildFilterTab("Range", AnalysisFilter.range),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Date Navigator ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _previousPeriod,
                        color: Colors.black54,
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_selectedFilter == AnalysisFilter.range) {
                            _selectDateRange();
                          }
                        },
                        child: Text(
                          _getFormattedDateRange(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _nextPeriod,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Summary Cards ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          "Income",
                          totalIncome,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          "Expense",
                          totalExpense,
                          Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Bar Chart ---
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Trends Overview",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: filteredTransactions.isEmpty
                              ? const Center(
                                  child: Text("No Data for this period"),
                                )
                              : BarChart(
                                  BarChartData(
                                    barGroups: _getChartGroups(
                                      filteredTransactions,
                                    ),
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            // Logic to show titles sparsely
                                            int v = value.toInt();
                                            if (_selectedFilter ==
                                                AnalysisFilter.day) {
                                              return const SizedBox();
                                            }
                                            if (_selectedFilter ==
                                                AnalysisFilter.year) {
                                              return Text(
                                                DateFormat(
                                                  'MMM',
                                                ).format(DateTime(2023, v)),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              );
                                            }
                                            if (_selectedFilter ==
                                                AnalysisFilter.month) {
                                              if (v % 5 == 0) {
                                                return Text(
                                                  v.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                );
                                              }
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barTouchData: BarTouchData(
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipColor: (group) =>
                                            Colors.blueGrey.shade900,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Top Spends ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Top Spends",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          _sortDescending
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 16,
                        ),
                        label: Text(_sortDescending ? "Highest" : "Lowest"),
                        onPressed: () {
                          setState(() {
                            _sortDescending = !_sortDescending;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedTransactions.length > 5
                        ? 5
                        : sortedTransactions.length, // Show top 5
                    itemBuilder: (context, index) {
                      final t = sortedTransactions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: t.type == "Income"
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            child: Icon(
                              t.type == "Income"
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: t.type == "Income"
                                  ? Colors.green
                                  : Colors.red,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            t.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(DateTime.parse(t.date)),
                          ),
                          trailing: Text(
                            '₹${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: t.type == "Income"
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontSize: 16,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailScreen(
                                  transaction: t,
                                  isReadOnly: true,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  if (sortedTransactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text("No transactions found"),
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String text, AnalysisFilter filter) {
    bool isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        if (filter == AnalysisFilter.range) {
          _selectDateRange();
        } else {
          setState(() => _selectedFilter = filter);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A73E8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDateRange() {
    switch (_selectedFilter) {
      case AnalysisFilter.day:
        return DateFormat('dd MMM yyyy').format(_focusedDate);
      case AnalysisFilter.month:
        return DateFormat('MMMM yyyy').format(_focusedDate);
      case AnalysisFilter.year:
        return DateFormat('yyyy').format(_focusedDate);
      case AnalysisFilter.range:
        if (_customDateRange == null) return "Select Range";
        return "${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM').format(_customDateRange!.end)}";
    }
  }
}
