import 'package:flutter/material.dart'; 
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/discount_card_model.dart'; // <-- Добавлен импорт модели карт

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
      version: 3, // <-- Повысили версию до 3 для добавления новой таблицы
      onCreate: _createDB,
      onUpgrade: _onUpgrade, 
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

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

    await db.execute('''
      CREATE TABLE ${CategoryFields.table} (
        ${CategoryFields.id} $idType,
        ${CategoryFields.name} $textType,
        ${CategoryFields.iconCode} $intType,
        ${CategoryFields.isDefault} $intType,
        ${CategoryFields.budgetLimit} $realType DEFAULT 0.0
      )
    ''');

    // Таблица для скидочных карт (при чистой установке приложения)
    await db.execute('''
      CREATE TABLE ${DiscountCardFields.table} (
        ${DiscountCardFields.id} $idType,
        ${DiscountCardFields.storeName} $textType,
        ${DiscountCardFields.code} $textType,
        ${DiscountCardFields.format} $textType,
        ${DiscountCardFields.color} $intType
      )
    ''');

    await _seedCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${CategoryFields.table} ADD COLUMN ${CategoryFields.budgetLimit} REAL DEFAULT 0.0');
    }
    if (oldVersion < 3) {
      // Миграция для версии 3: Добавляем таблицу скидочных карт для существующих пользователей
      await db.execute('''
        CREATE TABLE ${DiscountCardFields.table} (
          ${DiscountCardFields.id} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${DiscountCardFields.storeName} TEXT NOT NULL,
          ${DiscountCardFields.code} TEXT NOT NULL,
          ${DiscountCardFields.format} TEXT NOT NULL,
          ${DiscountCardFields.color} INTEGER NOT NULL
        )
      ''');
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

  // --- Методы для Транзакций ---

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

  // --- Методы для Категорий ---

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

  // --- Методы для Скидочных Карт ---

  Future<int> createDiscountCard(DiscountCardModel card) async {
    final db = await instance.database;
    return await db.insert(DiscountCardFields.table, card.toMap());
  }

  Future<List<DiscountCardModel>> getAllDiscountCards() async {
    final db = await instance.database;
    final result = await db.query(DiscountCardFields.table, orderBy: '${DiscountCardFields.storeName} ASC');
    return result.map((json) => DiscountCardModel.fromMap(json)).toList();
  }

  Future<int> deleteDiscountCard(int id) async {
    final db = await instance.database;
    return await db.delete(DiscountCardFields.table, where: '${DiscountCardFields.id} = ?', whereArgs: [id]);
  }

  Future<int> updateDiscountCard(DiscountCardModel card) async {
    final db = await instance.database;
    return await db.update(DiscountCardFields.table, card.toMap(), where: '${DiscountCardFields.id} = ?', whereArgs: [card.id]);
  }
}