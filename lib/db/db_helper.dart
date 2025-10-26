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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            amount REAL,
            type TEXT,
            date TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE deleted_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            amount REAL,
            type TEXT,
            date TEXT
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
      },
    );
  }

  // ---------------------- ACTIVE TRANSACTIONS ----------------------
  Future<int> insertTransaction(TransactionModel txn) async {
    final db = await database;
    return await db.insert('transactions', txn.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------- DELETED TRANSACTIONS ----------------------
  Future<int> insertDeletedTransaction(TransactionModel txn) async {
    final db = await database;
    return await db.insert('deleted_transactions', txn.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TransactionModel>> getDeletedTransactions() async {
    final db = await database;
    final maps = await db.query('deleted_transactions', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }
}
