import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  final TextEditingController _customCategoryController =
      TextEditingController();

  late String _selectedType;
  String? _selectedCategory;
  late DateTime _selectedDate;
  late bool _isSplit;
  late int _splitCount;

  // Predefined categories
  final List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Business',
    'Gift',
    'Bonus',
    'Refund',
    'Others',
  ];

  final List<String> _expenseCategories = [
    'Food',
    'Petrol',
    'House Rent',
    'Shopping',
    'Transportation',
    'Bills & Utilities',
    'Entertainment',
    'Healthcare',
    'Education',
    'Travel',
    'Groceries',
    'Mobile Recharge',
    'Internet',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with existing transaction data
    _nameController = TextEditingController(text: widget.transaction.name);
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.transaction.description,
    );
    _selectedType = widget.transaction.type;
    _selectedDate = DateTime.parse(widget.transaction.date);
    _isSplit = widget.transaction.isSplit;
    _splitCount = widget.transaction.splitCount;

    // Check if category is in predefined list
    final categories = _selectedType == 'Income'
        ? _incomeCategories
        : _expenseCategories;
    if (categories.contains(widget.transaction.category)) {
      _selectedCategory = widget.transaction.category;
    } else {
      _selectedCategory = 'Others';
      _customCategoryController.text = widget.transaction.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A73E8),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _updateTransaction() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a category'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      // Use custom category if "Others" is selected
      String finalCategory = _selectedCategory!;
      if (_selectedCategory == 'Others') {
        if (_customCategoryController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enter a custom category'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }
        finalCategory = _customCategoryController.text.trim();
      }

      final updatedTxn = TransactionModel(
        id: widget.transaction.id,
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        category: finalCategory,
        type: _selectedType,
        date: _selectedDate.toString().split(' ')[0],
        description: _descriptionController.text.trim(),
        isSplit: _isSplit,
        splitCount: _isSplit ? _splitCount : 1,
      );

      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).updateTransaction(updatedTxn);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Transaction updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pop(context);
      Navigator.pop(context); // Pop detail screen too
    }
  }

  @override
  Widget build(BuildContext context) {
    final splitAmount = _isSplit && _amountController.text.isNotEmpty
        ? (double.tryParse(_amountController.text) ?? 0) / _splitCount
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Transaction',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1A73E8),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name Field
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Transaction name',
                    prefixIcon: Icon(Icons.label, color: Colors.blue),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter transaction name' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Amount Field with Split Toggle
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: const Icon(
                          Icons.currency_rupee,
                          color: Colors.teal,
                        ),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isSplit = !_isSplit;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _isSplit
                                    ? const Color(0xFF1A73E8)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_alt,
                                    size: 18,
                                    color: _isSplit
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Split',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _isSplit
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? 'Enter amount' : null,
                      onChanged: (value) {
                        setState(() {}); // Rebuild to update split amount
                      },
                    ),
                    if (_isSplit)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1A73E8,
                          ).withValues(alpha: 0.08),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Split between',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: _splitCount > 2
                                                ? () {
                                                    setState(() {
                                                      _splitCount--;
                                                    });
                                                  }
                                                : null,
                                            icon: const Icon(Icons.remove),
                                            iconSize: 18,
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            color: const Color(0xFF1A73E8),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              '$_splitCount',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1A73E8),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _splitCount < 20
                                                ? () {
                                                    setState(() {
                                                      _splitCount++;
                                                    });
                                                  }
                                                : null,
                                            icon: const Icon(Icons.add),
                                            iconSize: 18,
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            color: const Color(0xFF1A73E8),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'people',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (splitAmount > 0) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade50,
                                      Colors.green.shade100,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 20,
                                          color: Colors.green.shade700,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Per person:',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '₹${splitAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category, color: Colors.orange),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  hint: const Text('Select a category'),
                  items:
                      (_selectedType == 'Income'
                              ? _incomeCategories
                              : _expenseCategories)
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      if (value != 'Others') {
                        _customCategoryController.clear();
                      }
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Select a category' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Custom Category Field
              if (_selectedCategory == 'Others')
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: TextFormField(
                    controller: _customCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Category',
                      hintText: 'Enter your category',
                      prefixIcon: Icon(Icons.edit, color: Colors.deepOrange),
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              if (_selectedCategory == 'Others') const SizedBox(height: 16),

              // Description Field
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Add notes about this transaction',
                    prefixIcon: Icon(Icons.notes, color: Colors.purple),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(height: 16),

              // Type Toggle Buttons
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: ['Income', 'Expense'].map((type) {
                    final isSelected = _selectedType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = type;
                            // Reset category when type changes
                            final categories = type == 'Income'
                                ? _incomeCategories
                                : _expenseCategories;
                            if (!categories.contains(_selectedCategory)) {
                              _selectedCategory = null;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (type == 'Income'
                                      ? Colors.green
                                      : Colors.redAccent)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type == 'Income'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black54,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                type,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Date Picker
              GestureDetector(
                onTap: () => _pickDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1A73E8)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date: ${_selectedDate.toString().split(' ')[0]}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(Icons.calendar_month, color: Colors.teal),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Update Button
              ElevatedButton(
                onPressed: _updateTransaction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF1A73E8),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Update Transaction',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
