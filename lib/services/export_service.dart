import 'dart:convert';
import 'dart:io';

// CSV parsing implemented inline; no external csv/cross_file required.
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart';

class ExportService {
  ExportService._();
  static final instance = ExportService._();

  Future<String> exportTransactionsCsv(List<TransactionModel> txs) async {
    final rows = <List<dynamic>>[];
    rows.add(['id', 'title', 'amount', 'date', 'category', 'isIncome']);
    for (final t in txs) {
      rows.add([
        t.id,
        t.title,
        t.amount.toStringAsFixed(2),
        t.date.toIso8601String(),
        t.category,
        t.isIncome ? '1' : '0',
      ]);
    }

    // Simple CSV encoding (handles quotes and commas)
    final csv = rows.map((r) {
      return r.map((v) {
        final s = v?.toString() ?? '';
        if (s.contains(',') || s.contains('"') || s.contains('\n')) {
          return '"${s.replaceAll('"', '""')}"';
        }
        return s;
      }).join(',');
    }).join('\n');
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/smartfinance_transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv, flush: true);
    return file.path;
  }

  Future<void> shareFile(String path) async {
    await Share.shareXFiles([
      XFile(path),
    ], text: 'SmartFinance transactions export');
  }

  Future<List<TransactionModel>> importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return [];

    final path = result.files.single.path!;
    final content = await File(path).readAsString();
    // Simple CSV parsing (handles quoted fields)
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) return [];
    final List<TransactionModel> out = [];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      final List<String> r = [];
      final buffer = StringBuffer();
      bool inQuotes = false;
      for (var j = 0; j < line.length; j++) {
        final ch = line[j];
        if (ch == '"') {
          if (inQuotes && j + 1 < line.length && line[j + 1] == '"') {
            buffer.write('"');
            j++;
          } else {
            inQuotes = !inQuotes;
          }
        } else if (ch == ',' && !inQuotes) {
          r.add(buffer.toString());
          buffer.clear();
        } else {
          buffer.write(ch);
        }
      }
      r.add(buffer.toString());
      try {
        final id = r[0].toString();
        final title = r[1].toString();
        final amount = double.tryParse(r[2].toString()) ?? 0.0;
        final date = DateTime.parse(r[3].toString());
        final category = r.length > 4 ? r[4].toString() : 'General';
        final isIncome = (r.length > 5 ? r[5].toString() : '0') == '1';
        out.add(
          TransactionModel(
            id: id,
            title: title,
            amount: amount,
            date: date,
            category: category,
            isIncome: isIncome,
          ),
        );
      } catch (_) {
        // skip rows that fail
      }
    }
    return out;
  }

  Future<String> backupJson(Map<String, dynamic> data) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/smartfinance_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonEncode(data), flush: true);
    return file.path;
  }

  Future<Map<String, dynamic>?> restoreJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path!;
    final content = await File(path).readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }
}
