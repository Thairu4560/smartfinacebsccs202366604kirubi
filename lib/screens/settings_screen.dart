import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/transaction_provider.dart';
import '../services/export_service.dart';
import '../models/transaction.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<TransactionProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _ProfileEditor(),
            const SizedBox(height: 16),
            const Text(
              'Backup & Restore',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final data = {
                  'transactions': prov.transactions
                      .map((t) => t.toJson())
                      .toList(),
                  'monthlyIncome': prov.monthlyIncome,
                  'categoryBudgets': prov.categoryBudgets,
                };
                final path = await ExportService.instance.backupJson(data);
                messenger.showSnackBar(
                  SnackBar(content: Text('Backup saved to $path')),
                );
              },
              icon: const Icon(Icons.backup),
              label: const Text('Create Backup (JSON)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final data = {
                  'transactions': prov.transactions
                      .map((t) => t.toJson())
                      .toList(),
                  'monthlyIncome': prov.monthlyIncome,
                  'categoryBudgets': prov.categoryBudgets,
                };
                final path = await ExportService.instance.backupJson(data);
                await ExportService.instance.shareFile(path);
              },
              icon: const Icon(Icons.share),
              label: const Text('Share Backup'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final map = await ExportService.instance.restoreJson();
                if (map == null) return;
                try {
                  final items = (map['transactions'] as List)
                      .map(
                        (e) => TransactionModel.fromJson(
                          Map<String, dynamic>.from(e),
                        ),
                      )
                      .toList();
                  for (var t in items) {
                    prov.addTransaction(t);
                  }
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Restored ${items.length} transactions'),
                    ),
                  );
                } catch (_) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Invalid backup file')),
                  );
                }
              },
              icon: const Icon(Icons.restore),
              label: const Text('Restore Backup (JSON)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileEditor extends StatefulWidget {
  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  static const _kName = 'sf_profile_name_v1';
  static const _kUniv = 'sf_profile_univ_v1';
  final _nameC = TextEditingController();
  final _univC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _nameC.text = p.getString(_kName) ?? 'Student';
    _univC.text = p.getString(_kUniv) ?? 'Your University';
    setState(() {});
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, _nameC.text.trim());
    await p.setString(_kUniv, _univC.text.trim());
    messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameC,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _univC,
          decoration: const InputDecoration(labelText: 'University'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _save, child: const Text('Save Profile')),
      ],
    );
  }
}
