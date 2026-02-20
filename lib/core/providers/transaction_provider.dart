import 'package:flutter/material.dart';
import '../../data/local/database_service.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = []; // Список категорий
  double _balance = 0.0;

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  double get balance => _balance;

  Future<void> loadData() async {
    _transactions = await DatabaseService.instance.getAllTransactions();
    _categories = await DatabaseService.instance.getAllCategories(); // Грузим категории
    _balance = await DatabaseService.instance.getBalance();
    notifyListeners();
  }

  // Транзакции
  Future<void> addTransaction(TransactionModel transaction) async {
    await DatabaseService.instance.createTransaction(transaction);
    await loadData();
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseService.instance.deleteTransaction(id);
    await loadData();
  }

  Future<void> editTransaction(TransactionModel transaction) async {
    await DatabaseService.instance.updateTransaction(transaction);
    await loadData();
  }

  // Категории
  Future<void> addCategory(String name, int iconCode, double limit) async {
    final newCat = CategoryModel(
      name: name, 
      iconCode: iconCode, 
      isDefault: false,
      budgetLimit: limit, // <--- Записываем лимит
    );
    await DatabaseService.instance.createCategory(newCat);
    await loadData();
  }

  Future<void> deleteCategory(int id) async {
    await DatabaseService.instance.deleteCategory(id);
    await loadData();
  }

  // ... (предыдущий код)

  // Обновление категории (например, для установки лимита)
  Future<void> updateCategory(CategoryModel category) async {
    await DatabaseService.instance.updateCategory(category);
    await loadData(); // Перезагружаем список, чтобы UI обновился
  }
} // конец класса
