import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/transaction_model.dart';
import '../common/custom_text_field.dart';

class TransactionForm extends StatefulWidget {
  final TransactionModel? initialTransaction;
  final String submitButtonText;
  final void Function(TransactionModel transaction) onSubmit;

  const TransactionForm({
    super.key,
    this.initialTransaction,
    required this.submitButtonText,
    required this.onSubmit,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
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

  @override
  void initState() {
    super.initState();
    final txn = widget.initialTransaction;

    _nameController = TextEditingController(text: txn?.name ?? '');
    _amountController = TextEditingController(
      text: txn?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: txn?.description ?? '',
    );

    _selectedType = txn?.type ?? 'Expense';
    _selectedDate = txn != null ? DateTime.parse(txn.date) : DateTime.now();
    _isSplit = txn?.isSplit ?? false;
    _splitCount = txn?.splitCount ?? 2;

    if (txn != null) {
      final categories = _selectedType == 'Income'
          ? AppConstants.incomeCategories
          : AppConstants.expenseCategories;

      if (categories.contains(txn.category)) {
        _selectedCategory = txn.category;
      } else {
        _selectedCategory = 'Others';
        _customCategoryController.text = txn.category;
      }
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

  void _handleSubmit() {
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

      final txn = TransactionModel(
        id: widget.initialTransaction?.id,
        name: _nameController.text.trim(),
        amount: double.parse(_amountController.text),
        category: finalCategory,
        type: _selectedType,
        date: _selectedDate.toString().split(' ')[0],
        description: _descriptionController.text.trim(),
        isSplit: _isSplit,
        splitCount: _isSplit ? _splitCount : 1,
      );

      widget.onSubmit(txn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final splitAmount = _isSplit && _amountController.text.isNotEmpty
        ? (double.tryParse(_amountController.text) ?? 0) / _splitCount
        : 0.0;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Name',
            hint: 'Transaction name',
            prefixIcon: Icons.label,
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                value!.isEmpty ? 'Enter transaction name' : null,
          ),
          const SizedBox(height: 16),
          _buildAmountField(splitAmount),
          const SizedBox(height: 16),
          _buildCategoryDropdown(),
          const SizedBox(height: 16),
          if (_selectedCategory == 'Others') ...[
            CustomTextField(
              controller: _customCategoryController,
              label: 'Custom Category',
              hint: 'Enter your category',
              prefixIcon: Icons.edit,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
          ],
          CustomTextField(
            controller: _descriptionController,
            label: 'Description (Optional)',
            hint: 'Add notes about this transaction',
            prefixIcon: Icons.notes,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          _buildTypeSelector(),
          const SizedBox(height: 24),
          _buildDatePicker(),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _handleSubmit,
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
              children: [
                const Icon(Icons.save_alt, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  widget.submitButtonText,
                  style: const TextStyle(
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
    );
  }

  Widget _buildAmountField(double splitAmount) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        children: [
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixIcon: const Icon(Icons.currency_rupee, color: Colors.teal),
              suffixIcon: Container(
                margin: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() => _isSplit = !_isSplit);
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
                          color: _isSplit ? Colors.white : Colors.grey.shade600,
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
              border: const OutlineInputBorder(borderSide: BorderSide.none),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter amount';
              }
              if (double.tryParse(value) == null) {
                return 'Enter a valid number';
              }
              return null;
            },
            onChanged: (value) => setState(() {}),
          ),
          if (_isSplit)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withValues(alpha: 0.08),
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
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _splitCount > 2
                                      ? () => setState(() => _splitCount--)
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
                                      ? () => setState(() => _splitCount++)
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
                          colors: [Colors.green.shade50, Colors.green.shade100],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    );
  }

  Widget _buildCategoryDropdown() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(
            Icons.category,
            color: Theme.of(context).primaryColor,
          ),
          border: const OutlineInputBorder(borderSide: BorderSide.none),
        ),
        hint: const Text('Select a category'),
        items:
            (_selectedType == 'Income'
                    ? AppConstants.incomeCategories
                    : AppConstants.expenseCategories)
                .map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
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
        validator: (value) => value == null ? 'Select a category' : null,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
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
                  _selectedCategory = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (type == 'Income' ? Colors.green : Colors.redAccent)
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
                      color: isSelected ? Colors.white : Colors.black54,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
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
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Icon(Icons.calendar_month, color: Colors.teal),
          ],
        ),
      ),
    );
  }
}
