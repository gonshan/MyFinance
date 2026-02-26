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
    _exchangeRates = await CurrencyService.fetchRates();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
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
    final int id = await DatabaseService.instance.createTransaction(transaction);
    final newTransaction = TransactionModel(
      id: id,
      amount: transaction.amount,
      category: transaction.category,
      date: transaction.date,
      isIncome: transaction.isIncome,
      comment: transaction.comment,
    );
    _transactions.insert(0, newTransaction);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    _balance += newTransaction.isIncome ? newTransaction.amount : -newTransaction.amount;
    notifyListeners();
  }

  Future<void> deleteTransaction(int id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      final t = _transactions[index];
      _balance -= t.isIncome ? t.amount : -t.amount;
      _transactions.removeAt(index);
      notifyListeners();
    }
    await DatabaseService.instance.deleteTransaction(id);
  }

  Future<void> editTransaction(TransactionModel transaction) async {
    await DatabaseService.instance.updateTransaction(transaction);
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      final oldT = _transactions[index];
      _balance -= oldT.isIncome ? oldT.amount : -oldT.amount;
      _balance += transaction.isIncome ? transaction.amount : -transaction.amount;
      _transactions[index] = transaction;
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
  }

  Future<void> addCategory(String name, int iconCode, double limit) async {
    final newCat = CategoryModel(
      name: name,
      iconCode: iconCode,
      isDefault: false,
      budgetLimit: limit,
    );
    final int id = await DatabaseService.instance.createCategory(newCat);
    final savedCat = CategoryModel(
      id: id,
      name: newCat.name,
      iconCode: newCat.iconCode,
      isDefault: newCat.isDefault,
      budgetLimit: newCat.budgetLimit,
    );
    _categories.add(savedCat);
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
    await DatabaseService.instance.deleteCategory(id);
  }

  Future<void> updateCategory(CategoryModel category) async {
    await DatabaseService.instance.updateCategory(category);
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
  }
}