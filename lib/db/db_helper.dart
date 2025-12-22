import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get database async {
    _db ??= await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ledger.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            category TEXT,
            amount REAL,
            type TEXT,
            date TEXT,
            description TEXT,
            isSplit INTEGER DEFAULT 0,
            splitCount INTEGER DEFAULT 1,
            splitAmount REAL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE deleted_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            category TEXT,
            amount REAL,
            type TEXT,
            date TEXT,
            description TEXT,
            isSplit INTEGER DEFAULT 0,
            splitCount INTEGER DEFAULT 1,
            splitAmount REAL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS deleted_transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category TEXT,
              amount REAL,
              type TEXT,
              date TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN name TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN description TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE deleted_transactions ADD COLUMN name TEXT DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE deleted_transactions ADD COLUMN description TEXT DEFAULT ""',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN isSplit INTEGER DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN splitCount INTEGER DEFAULT 1',
          );
          await db.execute(
            'ALTER TABLE transactions ADD COLUMN splitAmount REAL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE deleted_transactions ADD COLUMN isSplit INTEGER DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE deleted_transactions ADD COLUMN splitCount INTEGER DEFAULT 1',
          );
          await db.execute(
            'ALTER TABLE deleted_transactions ADD COLUMN splitAmount REAL DEFAULT 0',
          );
        }
      },
    );
  }

  // ---------------------- ACTIVE TRANSACTIONS ----------------------
  Future<int> insertTransaction(TransactionModel txn) async {
    final db = await database;
    return await db.insert(
      'transactions',
      txn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<int> updateTransaction(TransactionModel txn) async {
    final db = await database;
    return await db.update(
      'transactions',
      txn.toMap(),
      where: 'id = ?',
      whereArgs: [txn.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------- DELETED TRANSACTIONS ----------------------
  Future<int> insertDeletedTransaction(TransactionModel txn) async {
    final db = await database;
    return await db.insert(
      'deleted_transactions',
      txn.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getDeletedTransactions() async {
    final db = await database;
    final maps = await db.query('deleted_transactions', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }
}
