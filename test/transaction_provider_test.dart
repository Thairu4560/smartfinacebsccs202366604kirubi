import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smartfinance/providers/transaction_provider.dart';
import 'package:smartfinance/services/transaction_service.dart';
import 'package:smartfinance/models/transaction_model.dart';
import 'package:smartfinance/models/transaction.dart';

class MockTransactionService extends TransactionService {
  @override
  Future<void> init() async {
    // Mock init - do nothing
  }

  @override
  List<Transaction> getAllTransactions() => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Hive.initFlutter();
  });

  test('add and remove transaction', () async {
    final mockService = MockTransactionService();
    final prov = TransactionProvider(transactionService: mockService);
    final tx = TransactionModel(
      id: 't1',
      title: 'Lunch',
      amount: 200.0,
      date: DateTime.now(),
      category: 'Food',
      isIncome: false,
    );
    prov.addTransaction(tx);
    expect(prov.transactions.length, 1);
    expect(prov.totalExpense, 200.0);
    prov.removeTransaction('t1');
    expect(prov.transactions.isEmpty, true);
  });
}
