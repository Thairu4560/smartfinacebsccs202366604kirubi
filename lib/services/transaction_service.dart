import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';

class TransactionService {
  static const String _boxName = 'transactionsBox';
  late Box<Transaction> _transactionBox;

  Future<void> init() async {
    _transactionBox = await Hive.openBox<Transaction>(_boxName);
  }

  // Add a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    await _transactionBox.put(transaction.id, transaction);
  }

  // Get all transactions
  List<Transaction> getAllTransactions() {
    return _transactionBox.values.toList();
  }

  // Delete a transaction by ID
  Future<void> deleteTransaction(String id) async {
    await _transactionBox.delete(id);
  }

  // Clear all transactions
  Future<void> clearAllTransactions() async {
    await _transactionBox.clear();
  }

  // Get transactions by type
  List<Transaction> getTransactionsByType(String type) {
    return _transactionBox.values.where((transaction) => transaction.type == type).toList();
  }

  // Get transactions by category
  List<Transaction> getTransactionsByCategory(String category) {
    return _transactionBox.values.where((transaction) => transaction.category == category).toList();
  }

  // Calculate total income
  double get totalIncome {
    return getTransactionsByType('income')
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Calculate total expenses
  double get totalExpenses {
    return getTransactionsByType('expense')
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Calculate balance
  double get balance => totalIncome - totalExpenses;

  // Get spending by category
  Map<String, double> get spendingByCategory {
    final Map<String, double> spending = {};
    final expenses = getTransactionsByType('expense');

    for (final transaction in expenses) {
      spending[transaction.category] = (spending[transaction.category] ?? 0.0) + transaction.amount;
    }

    return spending;
  }

  // Calculate percentage of income spent per category
  Map<String, double> get categorySpendingPercentage {
    final Map<String, double> percentages = {};
    final spending = spendingByCategory;

    if (totalIncome == 0) return percentages;

    spending.forEach((category, amount) {
      percentages[category] = (amount / totalIncome) * 100;
    });

    return percentages;
  }

  // Generate spending analysis and suggestions
  List<String> getSpendingAnalysis() {
    final List<String> suggestions = [];
    final percentages = categorySpendingPercentage;

    // Check for overspending
    percentages.forEach((category, percentage) {
      if (category.toLowerCase() == 'food' && percentage > 30) {
        suggestions.add('⚠️ You are spending too much on food (${percentage.toStringAsFixed(1)}% of income).');
      } else if (category.toLowerCase() == 'transport' && percentage > 20) {
        suggestions.add('⚠️ You are spending too much on transport (${percentage.toStringAsFixed(1)}% of income).');
      } else if (category.toLowerCase() == 'entertainment' && percentage > 15) {
        suggestions.add('⚠️ You are spending too much on entertainment (${percentage.toStringAsFixed(1)}% of income).');
      }
    });

    // Check for good saving habits
    final savingsRate = (balance / totalIncome) * 100;
    if (savingsRate > 20) {
      suggestions.add('✅ Great job saving this month! You saved ${savingsRate.toStringAsFixed(1)}% of your income.');
    } else if (savingsRate > 0) {
      suggestions.add('✅ You are saving ${savingsRate.toStringAsFixed(1)}% of your income. Keep it up!');
    } else if (savingsRate < 0) {
      suggestions.add('⚠️ You are spending more than you earn. Consider creating a budget.');
    }

    // Check if no transactions
    if (getAllTransactions().isEmpty) {
      suggestions.add('💡 Start by adding your income and expenses to track your finances.');
    }

    return suggestions;
  }

  // Get recent transactions (last 10)
  List<Transaction> getRecentTransactions({int limit = 10}) {
    final allTransactions = getAllTransactions();
    allTransactions.sort((a, b) => b.date.compareTo(a.date));
    return allTransactions.take(limit).toList();
  }

  // Close the box (usually called when app is disposed)
  Future<void> close() async {
    await _transactionBox.close();
  }
}