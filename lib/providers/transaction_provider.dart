import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService;
  double _monthlyIncome = 0.0;
  final Map<String, double> _categoryBudgets = {};
  static const _kMonthlyIncomeKey = 'sf_monthly_income_v1';
  static const _kCategoryBudgetsKey = 'sf_category_budgets_v1';

  TransactionProvider({required TransactionService transactionService})
      : _transactionService = transactionService {
    _loadSettings();
  }

  // Convert old TransactionModel to new Transaction
  Transaction _convertToNewModel(TransactionModel old) {
    return Transaction(
      id: old.id,
      type: old.isIncome ? 'income' : 'expense',
      amount: old.amount,
      category: old.category,
      description: old.title,
      date: old.date,
    );
  }

  // Convert new Transaction to old TransactionModel for backward compatibility
  TransactionModel _convertToOldModel(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      title: transaction.description,
      amount: transaction.amount,
      date: transaction.date,
      category: transaction.category,
      isIncome: transaction.isIncome,
    );
  }

  List<TransactionModel> get transactions {
    final hiveTransactions = _transactionService.getAllTransactions();
    return hiveTransactions.map(_convertToOldModel).toList();
  }

  double get totalIncome => _transactionService.totalIncome;

  double get totalExpense => _transactionService.totalExpenses;

  double get balance => _transactionService.balance;

  double get monthlyIncome => _monthlyIncome;

  Map<String, double> get categoryBudgets => Map.unmodifiable(_categoryBudgets);

  Map<String, double> get categorySpending => _transactionService.spendingByCategory;

  List<String> get spendingSuggestions => _transactionService.getSpendingAnalysis();

  bool get hasTransactions => _transactionService.getAllTransactions().isNotEmpty;

  /// Get spending percentage by category
  Map<String, double> getCategorySpendingPercentage() {
    final income = totalIncome;
    if (income == 0) return {};

    final Map<String, double> percentages = {};
    categorySpending.forEach((category, amount) {
      percentages[category] = (amount / income) * 100;
    });
    return percentages;
  }

  /// Get financial suggestions based on spending patterns
  List<String> getFinancialSuggestions() {
    final suggestions = <String>[];
    final income = totalIncome;
    final savings = balance;

    if (income == 0) {
      return ['Add income to start tracking your finances.'];
    }

    final percentages = getCategorySpendingPercentage();

    // Check spending limits
    if (percentages['Food'] != null && percentages['Food']! > 30) {
      suggestions.add(
        '⚠️ You are spending too much on food (${percentages['Food']!.toStringAsFixed(1)}%). Try reducing eating out.',
      );
    }
    if (percentages['Transport'] != null && percentages['Transport']! > 20) {
      suggestions.add(
        '⚠️ You are spending too much on transport (${percentages['Transport']!.toStringAsFixed(1)}%). Consider public transport.',
      );
    }
    if (percentages['Entertainment'] != null && percentages['Entertainment']! > 15) {
      suggestions.add(
        '⚠️ You are spending too much on entertainment (${percentages['Entertainment']!.toStringAsFixed(1)}%).',
      );
    }

    // Savings check
    final savingsPercentage = (savings / income) * 100;
    if (savingsPercentage > 20) {
      suggestions.add(
        '✅ Great job saving! You\'re saving ${savingsPercentage.toStringAsFixed(1)}% of your income.',
      );
    } else if (savingsPercentage > 0) {
      suggestions.add(
        '💡 Try to increase your savings rate. Currently at ${savingsPercentage.toStringAsFixed(1)}%.',
      );
    } else if (savingsPercentage < 0) {
      suggestions.add(
        '⚠️ Warning: You\'re spending more than you earn. Review your expenses.',
      );
    }

    // Generic suggestions
    if (suggestions.isEmpty) {
      suggestions.add(
        '💡 Your spending is within recommended limits. Keep it up!',
      );
    }

    return suggestions;
  }

  void setMonthlyIncome(double value) {
    _monthlyIncome = value;
    notifyListeners();
    _saveSettings();
  }

  void setCategoryBudget(String category, double amount) {
    _categoryBudgets[category] = amount;
    notifyListeners();
    _saveSettings();
  }

  void addTransaction(TransactionModel tx) {
    final newTransaction = _convertToNewModel(tx);
    _transactionService.addTransaction(newTransaction);
    notifyListeners();
  }

  void removeTransaction(String id) {
    _transactionService.deleteTransaction(id);
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kMonthlyIncomeKey, _monthlyIncome);
      await prefs.setString(_kCategoryBudgetsKey, jsonEncode(_categoryBudgets));
    } catch (e) {
      if (kDebugMode) print('Failed saving settings: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _monthlyIncome = prefs.getDouble(_kMonthlyIncomeKey) ?? _monthlyIncome;

      final catJson = prefs.getString(_kCategoryBudgetsKey);
      if (catJson != null && catJson.isNotEmpty) {
        final decoded = jsonDecode(catJson) as Map<String, dynamic>;
        _categoryBudgets.clear();
        decoded.forEach((k, v) {
          _categoryBudgets[k] = (v as num).toDouble();
        });
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Failed loading settings: $e');
    }
  }
}
