import 'package:flutter/material.dart'; 
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
    _database = await _initDB('myfinance_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade, 
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // 1. Таблица транзакций
    await db.execute('''
      CREATE TABLE ${TransactionFields.table} (
        ${TransactionFields.id} $idType,
        ${TransactionFields.amount} $realType,
        ${TransactionFields.category} $textType,
        ${TransactionFields.date} $textType,
        ${TransactionFields.isIncome} $intType,
        ${TransactionFields.comment} $textType
      )
    ''');

    // 2. Таблица категорий
    await db.execute('''
      CREATE TABLE ${CategoryFields.table} (
        ${CategoryFields.id} $idType,
        ${CategoryFields.name} $textType,
        ${CategoryFields.iconCode} $intType,
        ${CategoryFields.isDefault} $intType,
        ${CategoryFields.budgetLimit} $realType DEFAULT 0.0
      )
    ''');

    await _seedCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${CategoryFields.table} ADD COLUMN ${CategoryFields.budgetLimit} REAL DEFAULT 0.0');
      debugPrint("Миграция БД: добавлено поле budgetLimit");
    }
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
      await db.insert(CategoryFields.table, cat.toMap());
    }
  }

  // --- Transactions CRUD ---
  Future<int> createTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert(TransactionFields.table, transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query(TransactionFields.table, orderBy: '${TransactionFields.date} DESC');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(TransactionFields.table, where: '${TransactionFields.id} = ?', whereArgs: [id]);
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update(TransactionFields.table, transaction.toMap(), where: '${TransactionFields.id} = ?', whereArgs: [transaction.id]);
  }

  Future<double> getBalance() async {
    final db = await instance.database;
    final incomeResult = await db.rawQuery('SELECT SUM(${TransactionFields.amount}) as total FROM ${TransactionFields.table} WHERE ${TransactionFields.isIncome} = 1');
    double income = (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final expenseResult = await db.rawQuery('SELECT SUM(${TransactionFields.amount}) as total FROM ${TransactionFields.table} WHERE ${TransactionFields.isIncome} = 0');
    double expense = (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return income - expense;
  }

  // --- Categories CRUD ---
  Future<int> createCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.insert(CategoryFields.table, category.toMap());
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query(CategoryFields.table);
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete(CategoryFields.table, where: '${CategoryFields.id} = ?', whereArgs: [id]);
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.update(CategoryFields.table, category.toMap(), where: '${CategoryFields.id} = ?', whereArgs: [category.id]);
  }
}