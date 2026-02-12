import 'package:flutter/material.dart'; // Нужен для Icons
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('myfinance_v2.db'); // Сменил имя, чтобы создать новую БД
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 1, 
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // 1. Таблица транзакций
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        amount $realType,
        category $textType,
        date $textType,
        isIncome $intType,
        comment $textType
      )
    ''');

    // 2. Таблица категорий
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        iconCode $intType,
        isDefault $intType
      )
    ''');

    // 3. Заполняем категории по умолчанию
    await _seedCategories(db);
  }

  Future<void> _seedCategories(Database db) async {
    final List<CategoryModel> defaults = [
      CategoryModel(name: 'Еда', iconCode: Icons.fastfood_rounded.codePoint, isDefault: true),
      CategoryModel(name: 'Транспорт', iconCode: Icons.directions_bus_rounded.codePoint, isDefault: true),
      CategoryModel(name: 'Дом', iconCode: Icons.home_rounded.codePoint, isDefault: true),
      CategoryModel(name: 'Развлечения', iconCode: Icons.movie_rounded.codePoint, isDefault: true),
      CategoryModel(name: 'Здоровье', iconCode: Icons.favorite_rounded.codePoint, isDefault: true),
      CategoryModel(name: 'Зарплата', iconCode: Icons.attach_money_rounded.codePoint, isDefault: true),
      CategoryModel(name: 'Подарки', iconCode: Icons.card_giftcard_rounded.codePoint, isDefault: true),
    ];

    for (var cat in defaults) {
      await db.insert('categories', cat.toMap());
    }
  }

  // --- Transactions CRUD ---
  Future<int> createTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update('transactions', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id]);
  }

  Future<double> getBalance() async {
    final db = await instance.database;
    final incomeResult = await db.rawQuery('SELECT SUM(amount) as total FROM transactions WHERE isIncome = 1');
    double income = (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;
    final expenseResult = await db.rawQuery('SELECT SUM(amount) as total FROM transactions WHERE isIncome = 0');
    double expense = (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;
    return income - expense;
  }

  // --- Categories CRUD ---
  Future<int> createCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}