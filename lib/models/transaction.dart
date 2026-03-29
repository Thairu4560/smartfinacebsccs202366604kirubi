import 'dart:convert';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final bool isIncome;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.category = 'General',
    this.isIncome = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category,
    'isIncome': isIncome,
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String? ?? 'General',
      isIncome: json['isIncome'] as bool? ?? false,
    );
  }

  static String encodeList(List<TransactionModel> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<TransactionModel> decodeList(String jsonStr) {
    final data = jsonDecode(jsonStr) as List<dynamic>;
    return data
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
