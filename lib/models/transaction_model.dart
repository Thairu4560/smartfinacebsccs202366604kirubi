import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // 'income' or 'expense'

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final DateTime date;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });

  // Helper getters
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  // Create copy with new values
  Transaction copyWith({
    String? id,
    String? type,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, category: $category, description: $description, date: $date)';
  }
}