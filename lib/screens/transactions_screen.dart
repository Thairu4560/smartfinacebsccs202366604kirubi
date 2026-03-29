import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../services/export_service.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions'), actions: [
        IconButton(
          tooltip: 'Export CSV',
          onPressed: prov.transactions.isEmpty
              ? null
              : () async {
                  final path = await ExportService.instance.exportTransactionsCsv(prov.transactions);
                  await ExportService.instance.shareFile(path);
                },
          icon: const Icon(Icons.share),
        ),
        IconButton(
          tooltip: 'Import CSV',
          onPressed: () async {
            final imported = await ExportService.instance.importCsv();
            if (imported.isNotEmpty) {
              for (var t in imported) {
                prov.addTransaction(t);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Imported ${imported.length} transactions')),
                );
              }
            }
          },
          icon: const Icon(Icons.file_upload),
        ),
      ]),
      body: prov.transactions.isEmpty
          ? const Center(child: Text('No transactions yet'))
          : ListView.builder(
              itemCount: prov.transactions.length,
              itemBuilder: (ctx, i) {
                final tx = prov.transactions[i];
                return Dismissible(
                  key: ValueKey(tx.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => prov.removeTransaction(tx.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(tx.title),
                    subtitle: Text(tx.date.toLocal().toString().split(' ')[0]),
                    trailing: Text(
                      "${tx.isIncome ? '+' : '-'}KES ${tx.amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: tx.isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleC = TextEditingController();
    final amountC = TextEditingController();
    String category = 'General';
    bool isIncome = false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleC,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: amountC,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            TextField(
              onChanged: (v) => category = v,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
              ),
            ),
            Row(
              children: [
                const Text('Income'),
                Switch(value: isIncome, onChanged: (v) => isIncome = v),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final title = titleC.text.trim();
              final amount = double.tryParse(amountC.text) ?? 0.0;
              if (title.isEmpty || amount <= 0) return;
              final tx = TransactionModel(
                id: DateTime.now().toIso8601String(),
                title: title,
                amount: amount,
                date: DateTime.now(),
                category: category,
                isIncome: isIncome,
              );
              Provider.of<TransactionProvider>(
                context,
                listen: false,
              ).addTransaction(tx);
              Navigator.of(ctx).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
