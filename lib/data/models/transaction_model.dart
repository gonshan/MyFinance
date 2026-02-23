class TransactionFields {
  static const String table = 'transactions';
  static const String id = 'id';
  static const String amount = 'amount';
  static const String category = 'category';
  static const String date = 'date';
  static const String isIncome = 'isIncome';
  static const String comment = 'comment';
}

class TransactionModel {
  final int? id;
  final double amount;
  final String category;
  final DateTime date;
  final bool isIncome;
  final String comment;

  TransactionModel({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.isIncome,
    this.comment = '',
  });

  Map<String, dynamic> toMap() {
    return {
      TransactionFields.id: id,
      TransactionFields.amount: amount,
      TransactionFields.category: category,
      TransactionFields.date: date.toIso8601String(),
      TransactionFields.isIncome: isIncome ? 1 : 0,
      TransactionFields.comment: comment,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map[TransactionFields.id],
      amount: map[TransactionFields.amount],
      category: map[TransactionFields.category],
      date: DateTime.parse(map[TransactionFields.date]),
      isIncome: map[TransactionFields.isIncome] == 1,
      comment: map[TransactionFields.comment],
    );
  }
}