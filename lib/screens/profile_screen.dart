import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/transaction_provider.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _kRemKey = 'sf_reminders_v1';
  List<Map<String, String>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<Map<String, String>> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('sf_profile_name_v1') ?? 'Student',
      'university': prefs.getString('sf_profile_univ_v1') ?? 'Your University',
      'email': prefs.getString('sf_profile_email_v1') ?? '',
    };
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kRemKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      final data = List<dynamic>.from(jsonDecode(jsonStr) as List<dynamic>);
      setState(
        () => _reminders = data
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
      );
    }
  }

  Future<void> _addReminder() async {
    final titleC = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Reminder'),
        content: TextField(
          controller: titleC,
          decoration: const InputDecoration(labelText: 'Note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final t = titleC.text.trim();
              if (t.isNotEmpty) {
                final item = {
                  'id': DateTime.now().toIso8601String(),
                  'text': t,
                };
                setState(() {
                  _reminders.insert(0, item);
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(_kRemKey, jsonEncode(_reminders));
                // schedule a weekly reminder (starts next occurrence at 09:00)
                try {
                  await NotificationService().scheduleWeeklyNotification(
                    item['id']!,
                    'SmartFinance Reminder',
                    t,
                  );
                } catch (_) {
                  // ignore notification errors (platform permissions may be required)
                }
              }
              if (!mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeReminder(String id) async {
    setState(() => _reminders.removeWhere((r) => r['id'] == id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRemKey, jsonEncode(_reminders));
  }

  Future<void> _editProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final nameC = TextEditingController(
      text: prefs.getString('sf_profile_name_v1') ?? 'Student',
    );
    final univC = TextEditingController(
      text: prefs.getString('sf_profile_univ_v1') ?? 'Your University',
    );
    final emailC = TextEditingController(
      text: prefs.getString('sf_profile_email_v1') ?? '',
    );

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: univC,
                decoration: const InputDecoration(labelText: 'University'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailC,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                ),
                keyboardType: TextInputType.emailAddress,
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
            onPressed: () async {
              await prefs.setString('sf_profile_name_v1', nameC.text.trim());
              await prefs.setString('sf_profile_univ_v1', univC.text.trim());
              await prefs.setString('sf_profile_email_v1', emailC.text.trim());
              if (!mounted) return;
              setState(() {}); // Refresh the UI
              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Profile updated')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetData() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data'),
        content: const Text(
          'This will delete all transactions, reminders, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('All data reset')));
              // Reset provider data
              // Note: Provider doesn't have a clear method, but we can reload
              setState(() {
                _reminders.clear();
              });
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  List<String> _getAchievements(TransactionProvider txProv) {
    final achievements = <String>[];
    final income = txProv.totalIncome;
    final expenses = txProv.totalExpense;
    final balance = txProv.balance;

    if (income > 0) {
      final savingsRate = balance / income;
      if (savingsRate >= 0.2) {
        achievements.add('🏆 Excellent Saver: Saved 20%+ of income');
      } else if (savingsRate >= 0.1) {
        achievements.add('💰 Good Saver: Saved 10%+ of income');
      } else if (savingsRate > 0) {
        achievements.add('📈 Started Saving: Positive balance maintained');
      }

      if (expenses < income * 0.8) {
        achievements.add('🎯 Budget Master: Stayed under 80% of income');
      }

      if (txProv.transactions.length >= 10) {
        achievements.add('📊 Tracking Pro: Recorded 10+ transactions');
      }
    }

    if (achievements.isEmpty) {
      achievements.add('🌱 Getting Started: Keep tracking your finances!');
    }

    return achievements;
  }

  @override
  Widget build(BuildContext context) {
    final txProv = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Information Section
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, String>>(
                    future: _loadProfile(),
                    builder: (ctx, snap) {
                      final data =
                          snap.data ??
                          {
                            'name': 'Student',
                            'university': 'Mount Kenya University',
                            'email': '',
                          };
                      return Column(
                        children: [
                          Text(
                            data['name']!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['university']!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (data['email']!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              data['email']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Financial Overview Section
          const Text(
            'Financial Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(
                  'Total Income',
                  txProv.totalIncome,
                  Colors.green,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFinancialCard(
                  'Total Expenses',
                  txProv.totalExpense,
                  Colors.red,
                  Icons.trending_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFinancialCard(
            'Current Balance',
            txProv.balance,
            Colors.blue,
            Icons.account_balance_wallet,
            isFullWidth: true,
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Savings Rate',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (txProv.totalIncome > 0) ...[
                    Text(
                      '${((txProv.balance / txProv.totalIncome) * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (txProv.balance / txProv.totalIncome).clamp(
                        0.0,
                        1.0,
                      ),
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Add income to see savings rate',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Achievements Section
          const Text(
            'Achievements',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._getAchievements(txProv).map((achievement) {
            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          // Settings Section
          const Text(
            'Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _editProfile,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.orange),
                  title: const Text('Reset Data'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _resetData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.grey),
                  title: const Text('Settings'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Reminders Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reminders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _addReminder,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _reminders.isEmpty
              ? Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No reminders yet.\nAdd reminders to stay on track.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: _reminders.map((reminder) {
                    return Dismissible(
                      key: ValueKey(reminder['id']),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _removeReminder(reminder['id']!),
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(reminder['text'] ?? ''),
                          trailing: const Icon(
                            Icons.swipe_left,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
          const SizedBox(height: 20),

          // App Info Section
          const Text(
            'App Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info, color: Colors.blue),
                    title: Text('SmartFinance'),
                    subtitle: Text('Version 1.0.0'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.school, color: Colors.green),
                    title: Text('Developer'),
                    subtitle: Text('Developed by patrick thairu kirubi'),
                  ),
                  ListTile(
                    leading: Icon(Icons.code, color: Colors.purple),
                    title: Text('Built with'),
                    subtitle: Text('Flutter & Dart'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(
    String title,
    double value,
    Color color,
    IconData icon, {
    bool isFullWidth = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
