import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vg_card.dart';

class DatabaseService {
  // Singleton pattern
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
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vanguard_db.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cards(
        id TEXT PRIMARY KEY,
        name TEXT,
        imageUrl TEXT,
        unitType TEXT,
        clan TEXT,
        nation TEXT,
        race TEXT,
        grade TEXT,
        power TEXT,
        critical TEXT,
        shield TEXT,
        skill TEXT,
        trigger TEXT,
        effectText TEXT,
        setName TEXT,
        rarity TEXT,
        regulation TEXT,
        illustrator TEXT,
        flavorText TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS cards');
      await _onCreate(db, newVersion);
    }
  }

  Future<void> insertCards(List<VgCard> cards) async {
    final db = await database;
    
    // Menggunakan batch untuk performa insert multiple data yang lebih optimal
    final batch = db.batch();
    for (var card in cards) {
      batch.insert(
        'cards',
        card.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<VgCard>> getCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cards');

    return List.generate(maps.length, (i) {
      return VgCard.fromJson(maps[i]);
    });
  }
}
