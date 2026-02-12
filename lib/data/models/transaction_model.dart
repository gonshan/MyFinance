class TransactionModel {
  final int? id;           // Уникальный номер (нужен базе)
  final double amount;     // Сумма [cite: 33]
  final String category;   // Категория (пока строкой) [cite: 34]
  final DateTime date;     // Дата [cite: 35]
  final bool isIncome;     // Тип: true = Доход, false = Расход [cite: 37]
  final String comment;    // Дополнительно: комментарий

  TransactionModel({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.isIncome,
    this.comment = '',
  });

  // Превращаем наш класс в "Карту" (Map), чтобы SQLite понял (упаковка)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(), // SQLite не понимает даты, храним как текст
      'isIncome': isIncome ? 1 : 0,   // SQLite не понимает bool, храним как 1 или 0
      'comment': comment,
    };
  }

  // Превращаем данные из базы обратно в наш класс (распаковка)
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      isIncome: map['isIncome'] == 1,
      comment: map['comment'],
    );
  }
}