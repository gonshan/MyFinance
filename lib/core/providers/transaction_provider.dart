import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/database_service.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../services/currency_service.dart';

class TransactionProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  double _balance = 0.0;
  bool _isLoading = true;
  
  List<CurrencyRate> _exchangeRates = [];
  String _currency = 'BYN';

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  double get balance => _balance;
  bool get isLoading => _isLoading;
  List<CurrencyRate> get exchangeRates => _exchangeRates;
  String get currency => _currency;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('main_currency') ?? 'BYN';

    _transactions = await DatabaseService.instance.getAllTransactions();
    _categories = await DatabaseService.instance.getAllCategories();
    _balance = await DatabaseService.instance.getBalance();

    try {
      _exchangeRates = await CurrencyService.fetchRates();
    } catch (e) {
      debugPrint('Ошибка загрузки курсов: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCurrency(String newCurrency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('main_currency', newCurrency);
    _currency = newCurrency;
    notifyListeners();
  }

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

  Future<void> addCategory(String name, int iconCode, double limit) async {
    final newCat = CategoryModel(
      name: name,
      iconCode: iconCode,
      isDefault: false,
      budgetLimit: limit,
    );
    await DatabaseService.instance.createCategory(newCat);
    await loadData();
  }

  Future<void> deleteCategory(int id) async {
    await DatabaseService.instance.deleteCategory(id);
    await loadData();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await DatabaseService.instance.updateCategory(category);
    await loadData();
  }
}