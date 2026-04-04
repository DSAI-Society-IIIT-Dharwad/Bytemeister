import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hack2future.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const idType = 'TEXT PRIMARY KEY';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE interactions (
        id $idType,
        date $textType,
        domain_type $textType,
        summary $textType,
        status $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE transcripts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        interaction_id $textType,
        sender $textType,
        content $textType,
        timestamp $textType,
        FOREIGN KEY (interaction_id) REFERENCES interactions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE extracted_entities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        interaction_id $textType,
        key $textType,
        value $textType,
        confidence $realType,
        is_verified INTEGER NOT NULL,
        FOREIGN KEY (interaction_id) REFERENCES interactions (id) ON DELETE CASCADE
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
