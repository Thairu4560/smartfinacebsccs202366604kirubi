import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/transaction_provider.dart';
import '../services/notification_service.dart';
import 'budget_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _kTipOverride = 'sf_tip_override_v1';
  int? _manualTipIdx;

  final List<String> _tips = const [
    'Save at least 10% of your income for emergencies.',
    'Cook at home to save on food costs.',
    'Track small daily expenses to find leaks.',
    'Set a weekly spending limit and stick to it.',
    'Avoid impulse purchases: wait 24 hours.',
    'Build an emergency fund: start small.',
    'Reduce unnecessary spending on fast food.',
    'Use public transport instead of taxis.',
    'Shop with a list to avoid buying extras.',
    'Review your subscriptions monthly.',
  ];

  @override
  void initState() {
    super.initState();
    _loadOverride();
  }

  Future<void> _loadOverride() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getInt(_kTipOverride);
    setState(() => _manualTipIdx = v);
  }

  Future<void> _setManualTip(int idx) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTipOverride, idx);
    setState(() => _manualTipIdx = idx);
  }

  int _weekIndex() {
    final start = DateTime(2020, 1, 1);
    final weeks = DateTime.now().toUtc().difference(start).inDays ~/ 7;
    return weeks % _tips.length;
  }

  String get _currentTip {
    if (_manualTipIdx != null &&
        _manualTipIdx! >= 0 &&
        _manualTipIdx! < _tips.length) {
      return _tips[_manualTipIdx!];
    }
    return _tips[_weekIndex()];
  }

  Future<String> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sf_profile_name_v1') ?? 'Student';
  }

  @override
  Widget build(BuildContext context) {
    final txProv = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartFinance'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Welcome Section
          FutureBuilder<String>(
            future: _getUserName(),
            builder: (context, snapshot) {
              final userName = snapshot.data ?? 'Student';
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $userName! 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage your finances wisely',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Financial Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Income',
                  txProv.totalIncome,
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Expenses',
                  txProv.totalExpense,
                  Colors.red,
                  Icons.trending_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            'Remaining Balance',
            txProv.balance,
            Colors.blue,
            Icons.account_balance_wallet,
            isFullWidth: true,
          ),
          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Add Income',
                  Icons.attach_money,
                  Colors.green,
                  () => _navigateToBudget(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionButton(
                  'Add Expense',
                  Icons.money_off,
                  Colors.red,
                  () => _navigateToBudget(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'View Budget',
                  Icons.account_balance_wallet,
                  Colors.blue,
                  () => _navigateToBudget(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickActionButton(
                  'Take Quiz',
                  Icons.quiz,
                  Colors.purple,
                  () => _navigateToQuiz(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Transactions
          const Text(
            'Recent Transactions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRecentTransactions(txProv),
          const SizedBox(height: 24),

          // Tips Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber),
                      const SizedBox(width: 8),
                      const Text(
                        'Financial Tip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentTip,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          final next = (_manualTipIdx ?? _weekIndex()) + 1;
                          _setManualTip(next % _tips.length);
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Next Tip'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            await NotificationService()
                                .scheduleWeeklyNotification(
                                  'tip_${DateTime.now().millisecondsSinceEpoch}',
                                  'SmartFinance Tip',
                                  _currentTip,
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Weekly tip scheduled'),
                              ),
                            );
                          } catch (_) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not schedule notification',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.notifications, size: 16),
                        label: const Text('Schedule'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double value,
    Color color,
    IconData icon, {
    bool isFullWidth = false,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
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

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(TransactionProvider txProv) {
    final recentTransactions = txProv.transactions.take(5).toList();

    if (recentTransactions.isEmpty) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No transactions yet.\nStart by adding income or expenses.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Column(
      children: recentTransactions.map((tx) {
        final isIncome = tx.isIncome;
        final icon = isIncome ? Icons.arrow_downward : Icons.arrow_upward;
        final bgColor = isIncome ? Colors.green : Colors.red;
        final amountSign = isIncome ? '+' : '-';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: bgColor.withValues(alpha: 0.2),
              child: Icon(icon, color: bgColor, size: 16),
            ),
            title: Text(
              tx.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${tx.category} • ${_formatDate(tx.date)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Text(
              '$amountSign KSH ${tx.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: bgColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _navigateToBudget(BuildContext context) {
    // Use a simple navigation approach - push the budget screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BudgetScreen()));
  }

  void _navigateToQuiz(BuildContext context) {
    // Use a simple navigation approach - push the quiz screen
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QuizScreen()));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
