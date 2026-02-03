import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'ledger_book.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        userId TEXT,
        name TEXT,
        category TEXT,
        amount REAL,
        type TEXT,
        date TEXT,
        description TEXT,
        isSplit INTEGER,
        splitCount INTEGER,
        splitAmount REAL,
        createdAt TEXT,
        isDeleted INTEGER DEFAULT 0,
        deletedAt TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add missing columns for soft delete support
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN isDeleted INTEGER DEFAULT 0',
        );
      } catch (_) {
        // Column might already exist
      }
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN deletedAt TEXT');
      } catch (_) {
        // Column might already exist
      }
    }
  }

  // Convert TransactionModel to Map for SQLite
  Map<String, dynamic> _toSqlMap(String userId, TransactionModel txn) {
    return {
      'id': txn.id,
      'userId': userId,
      'name': txn.name,
      'category': txn.category,
      'amount': txn.amount,
      'type': txn.type,
      'date': txn.date,
      'description': txn.description,
      'isSplit': txn.isSplit ? 1 : 0,
      'splitCount': txn.splitCount,
      'splitAmount': txn.splitAmount,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // Insert Transaction
  Future<void> insertTransaction(String userId, TransactionModel txn) async {
    final db = await database;
    // Generate an ID if it doesn't exist (though model usually has one or null)
    if (txn.id == null || txn.id!.isEmpty) {
      txn.id = DateTime.now().millisecondsSinceEpoch.toString();
    }
    await db.insert(
      'transactions',
      _toSqlMap(userId, txn),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get Transactions for User
  Future<List<TransactionModel>> getTransactions(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'userId = ? AND (isDeleted = 0 OR isDeleted IS NULL)',
      whereArgs: [userId],
      orderBy: 'date DESC, createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel(
        id: maps[i]['id'] as String?,
        name: maps[i]['name'] as String,
        category: maps[i]['category'] as String,
        amount: (maps[i]['amount'] as num).toDouble(),
        type: maps[i]['type'] as String,
        date: maps[i]['date'] as String,
        description: maps[i]['description'] as String,
        isSplit: (maps[i]['isSplit'] as int) == 1,
        splitCount: maps[i]['splitCount'] as int,
        splitAmount: (maps[i]['splitAmount'] as num).toDouble(),
      );
    });
  }

  // Update Transaction
  Future<void> updateTransaction(String userId, TransactionModel txn) async {
    final db = await database;
    await db.update(
      'transactions',
      _toSqlMap(userId, txn),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  // Soft Delete Transaction (mark as deleted, don't remove from DB)
  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.update(
      'transactions',
      {'isDeleted': 1, 'deletedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Restore Transaction (mark as not deleted)
  Future<void> restoreTransaction(String id) async {
    final db = await database;
    await db.update(
      'transactions',
      {'isDeleted': 0, 'deletedAt': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Permanently Delete Transaction from DB
  Future<void> permanentlyDeleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> getDeletedTransactions(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'userId = ? AND isDeleted = 1',
      whereArgs: [userId],
      orderBy: 'deletedAt DESC, date DESC',
    );

    return List.generate(maps.length, (i) {
      return TransactionModel(
        id: maps[i]['id'] as String?,
        name: maps[i]['name'] as String,
        category: maps[i]['category'] as String,
        amount: (maps[i]['amount'] as num).toDouble(),
        type: maps[i]['type'] as String,
        date: maps[i]['date'] as String,
        description: maps[i]['description'] as String,
        isSplit: (maps[i]['isSplit'] as int) == 1,
        splitCount: maps[i]['splitCount'] as int,
        splitAmount: (maps[i]['splitAmount'] as num).toDouble(),
      );
    });
  }
}
