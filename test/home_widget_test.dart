import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smartfinance/providers/transaction_provider.dart';
import 'package:smartfinance/services/transaction_service.dart';
import 'package:smartfinance/models/transaction_model.dart';
import 'package:smartfinance/screens/home_screen.dart';

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

  testWidgets('HomeScreen shows totals and tip', (WidgetTester tester) async {
    final mockService = MockTransactionService();
    final prov = TransactionProvider(transactionService: mockService);

    await tester.pumpWidget(
      ChangeNotifierProvider<TransactionProvider>.value(
        value: prov,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Remaining Balance'), findsOneWidget);

    // Scroll to make sure the tip is visible
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Financial Tip'), findsOneWidget);
  });
}
