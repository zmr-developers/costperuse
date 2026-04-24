import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/purchase.dart';
import '../models/usage_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('costperuse.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cost REAL NOT NULL,
        purchaseDate TEXT NOT NULL,
        category TEXT NOT NULL,
        expectedLifespan INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE usage_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchaseId INTEGER NOT NULL,
        usageDate TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (purchaseId) REFERENCES purchases(id)
      )
    ''');
  }

  Future<int> insertPurchase(Purchase purchase) async {
    final db = await database;
    return await db.insert('purchases', purchase.toMap());
  }

  Future<List<Purchase>> getPurchases() async {
    final db = await database;
    final maps = await db.query('purchases', orderBy: 'purchaseDate DESC');
    return maps.map((m) => Purchase.fromMap(m)).toList();
  }

  Future<int> deletePurchase(int id) async {
    final db = await database;
    await db.delete('usage_logs', where: 'purchaseId = ?', whereArgs: [id]);
    return await db.delete('purchases', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertUsageLog(UsageLog log) async {
    final db = await database;
    return await db.insert('usage_logs', log.toMap());
  }

  Future<List<UsageLog>> getUsageLogs(int purchaseId) async {
    final db = await database;
    final maps = await db.query('usage_logs', where: 'purchaseId = ?', whereArgs: [purchaseId], orderBy: 'usageDate DESC');
    return maps.map((m) => UsageLog.fromMap(m)).toList();
  }

  Future<int> getUsageCount(int purchaseId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM usage_logs WHERE purchaseId = ?', [purchaseId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteUsageLog(int id) async {
    final db = await database;
    return await db.delete('usage_logs', where: 'id = ?', whereArgs: [id]);
  }
}
