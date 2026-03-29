import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // Expense categories for students
  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'Books',
    'Rent',
    'Entertainment',
    'Other',
  ];

  // Controllers for income dialog
  final _incomeSourceController = TextEditingController();
  final _incomeAmountController = TextEditingController();
  DateTime? _selectedIncomeDate;

  // Controllers for expense dialog
  String? _selectedExpenseCategory;
  final _expenseDescriptionController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  DateTime? _selectedExpenseDate;

  @override
  void dispose() {
    _incomeSourceController.dispose();
    _incomeAmountController.dispose();
    _expenseDescriptionController.dispose();
    _expenseAmountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<TransactionProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget & Expense Tracker'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSummaryCard(
                    'Total Income',
                    prov.totalIncome,
                    Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard(
                    'Total Expenses',
                    prov.totalExpense,
                    Colors.red,
                  ),
                  const SizedBox(width: 12),
                  _buildSummaryCard('Balance', prov.balance, Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.attach_money),
                  label: const Text('Add Income'),
                  onPressed: () => _showAddIncomeDialog(context, prov),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.money_off),
                  label: const Text('Add Expense'),
                  onPressed: () => _showAddExpenseDialog(context, prov),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Transactions Section
            const Text(
              'Recent Transactions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            prov.transactions.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No transactions yet.\nStart by adding income or expenses.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: prov.transactions.length,
                    itemBuilder: (ctx, i) {
                      final tx = prov.transactions[i];
                      return _buildTransactionCard(ctx, tx, prov);
                    },
                  ),
            const SizedBox(height: 24),

            // Spending Analysis Section
            const Text(
              'Spending Analysis by Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            _buildSpendingAnalysis(prov),
            const SizedBox(height: 24),

            // Financial Suggestions Section
            const Text(
              'Financial Insights',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            _buildSuggestions(prov),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'KSH ${value.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel tx,
    TransactionProvider prov,
  ) {
    final isIncome = tx.isIncome;
    final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
    final bgColor = isIncome ? Colors.green : Colors.red;
    final amountSign = isIncome ? '+' : '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: bgColor.withValues(alpha: 0.2),
          child: Icon(icon, color: bgColor),
        ),
        title: Text(
          tx.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${tx.category} • ${_formatDate(tx.date)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            Text(
              '$amountSign KSH ${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: bgColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 18),
              onPressed: () => _confirmDeleteTransaction(context, tx.id, prov),
              tooltip: 'Delete',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingAnalysis(TransactionProvider prov) {
    final income = prov.totalIncome;
    if (income == 0 || !prov.hasTransactions) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Add transactions to see spending analysis.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final percentages = prov.getCategorySpendingPercentage();
    if (percentages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No expenses to analyze yet.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: percentages.entries.map((e) {
        final percentage = e.value;
        final isHigh = percentage > 20;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isHigh ? Colors.orange : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isHigh ? Colors.orange : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestions(TransactionProvider prov) {
    final suggestions = prov.getFinancialSuggestions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: suggestions.map((suggestion) {
        final isPositive = suggestion.contains('✅');
        final isWarning = suggestion.contains('⚠️');

        Color bgColor;
        Color borderColor;
        if (isPositive) {
          bgColor = Colors.green.withValues(alpha: 0.1);
          borderColor = Colors.green.withValues(alpha: 0.3);
        } else if (isWarning) {
          bgColor = Colors.orange.withValues(alpha: 0.1);
          borderColor = Colors.orange.withValues(alpha: 0.3);
        } else {
          bgColor = Colors.blue.withValues(alpha: 0.1);
          borderColor = Colors.blue.withValues(alpha: 0.3);
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              suggestion,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showAddIncomeDialog(BuildContext context, TransactionProvider prov) {
    _selectedIncomeDate = DateTime.now();
    _incomeSourceController.clear();
    _incomeAmountController.clear();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add Income'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _incomeSourceController,
                      decoration: InputDecoration(
                        labelText: 'Income Source',
                        hintText: 'e.g., Allowance, Scholarship, Part-time Job',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _incomeAmountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (KES)',
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.currency_pound),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text('Date: ${_formatDate(_selectedIncomeDate!)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: _selectedIncomeDate!,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedIncomeDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final source = _incomeSourceController.text.trim();
                    final amount =
                        double.tryParse(_incomeAmountController.text) ?? 0.0;

                    if (source.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill in all fields with valid data',
                          ),
                        ),
                      );
                      return;
                    }

                    prov.addTransaction(
                      TransactionModel(
                        id: DateTime.now().toIso8601String(),
                        title: source,
                        amount: amount,
                        date: _selectedIncomeDate ?? DateTime.now(),
                        category: source,
                        isIncome: true,
                      ),
                    );

                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Income of KSH ${amount.toStringAsFixed(2)} added successfully',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddExpenseDialog(BuildContext context, TransactionProvider prov) {
    _selectedExpenseCategory = expenseCategories.first;
    _selectedExpenseDate = DateTime.now();
    _expenseDescriptionController.clear();
    _expenseAmountController.clear();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add Expense'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedExpenseCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: expenseCategories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedExpenseCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _expenseDescriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'e.g., Lunch, Bus fare',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _expenseAmountController,
                      decoration: InputDecoration(
                        labelText: 'Amount (KES)',
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.currency_pound),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(
                        'Date: ${_formatDate(_selectedExpenseDate!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: _selectedExpenseDate!,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedExpenseDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final description = _expenseDescriptionController.text
                        .trim();
                    final amount =
                        double.tryParse(_expenseAmountController.text) ?? 0.0;

                    if (amount <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                        ),
                      );
                      return;
                    }

                    prov.addTransaction(
                      TransactionModel(
                        id: DateTime.now().toIso8601String(),
                        title: description.isEmpty
                            ? _selectedExpenseCategory!
                            : description,
                        amount: amount,
                        date: _selectedExpenseDate ?? DateTime.now(),
                        category: _selectedExpenseCategory ?? 'Other',
                        isIncome: false,
                      ),
                    );

                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Expense of KSH ${amount.toStringAsFixed(2)} added to ${_selectedExpenseCategory!}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTransaction(
    BuildContext context,
    String id,
    TransactionProvider prov,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text(
            'Are you sure you want to delete this transaction?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                prov.removeTransaction(id);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
