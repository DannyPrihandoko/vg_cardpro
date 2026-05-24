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
      version: 6,
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
        flavorText TEXT,
        mechanicTags TEXT
      )
    ''');
    await _createDeckTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS cards');
      await _onCreate(db, newVersion);
      return;
    }
    if (oldVersion < 4) {
      await _createDeckTables(db);
    }
    if (oldVersion < 5) {
      // Add mechanicTags column for AI recommendation system
      await db.execute(
        'ALTER TABLE cards ADD COLUMN mechanicTags TEXT',
      );
    }
    if (oldVersion < 6) {
      // Force recreation of cards table to reload newly optimized translations
      await db.execute('DROP TABLE IF EXISTS cards');
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
          flavorText TEXT,
          mechanicTags TEXT
        )
      ''');
    }
  }

  Future<void> _createDeckTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS decks(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        nation TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS deck_cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deckId TEXT NOT NULL,
        cardId TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        isRideLine INTEGER NOT NULL DEFAULT 0,
        rideLineGrade INTEGER NOT NULL DEFAULT -1,
        FOREIGN KEY (deckId) REFERENCES decks(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── Cards ──────────────────────────────────────────────────────────────

  Future<void> insertCards(List<VgCard> cards) async {
    final db = await database;
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
    return List.generate(maps.length, (i) => VgCard.fromJson(maps[i]));
  }

  /// Look up a card dynamically by its exact/partial number or name.
  Future<VgCard?> findCardByNumberOrName(String term) async {
    final db = await database;
    final cleanTerm = term.trim();
    if (cleanTerm.isEmpty) return null;

    // 1. Try exact match on ID (case-insensitive)
    final exactIdRows = await db.query(
      'cards',
      where: 'LOWER(id) = ?',
      whereArgs: [cleanTerm.toLowerCase()],
      limit: 1,
    );
    if (exactIdRows.isNotEmpty) {
      return VgCard.fromJson(exactIdRows.first);
    }

    // 2. Try prefix match on extracted base card number (e.g. DZ-SS14/001 from DZ-SS14/001R)
    final baseNum = _getBaseCardNumber(cleanTerm);
    final baseIdRows = await db.query(
      'cards',
      where: 'LOWER(id) = ? OR id LIKE ?',
      whereArgs: [baseNum.toLowerCase(), '$baseNum%'],
      limit: 1,
    );
    if (baseIdRows.isNotEmpty) {
      return VgCard.fromJson(baseIdRows.first);
    }

    // 3. Try exact case-insensitive match on Name
    final exactNameRows = await db.query(
      'cards',
      where: 'LOWER(name) = ?',
      whereArgs: [cleanTerm.toLowerCase()],
      limit: 1,
    );
    if (exactNameRows.isNotEmpty) {
      return VgCard.fromJson(exactNameRows.first);
    }

    // 4. Try fuzzy match on Name (contains)
    final fuzzyNameRows = await db.query(
      'cards',
      where: 'name LIKE ?',
      whereArgs: ['%$cleanTerm%'],
      limit: 1,
    );
    if (fuzzyNameRows.isNotEmpty) {
      return VgCard.fromJson(fuzzyNameRows.first);
    }

    return null;
  }

  /// Normalize a card number to its primary alphanumeric base before rarity/foil suffixes
  String _getBaseCardNumber(String raw) {
    final clean = raw.trim().toUpperCase();
    final regex = RegExp(r'^([A-Z0-9-]+/[0-9]+|[A-Z0-9]+-[0-9]+)');
    final match = regex.firstMatch(clean);
    if (match != null) {
      return match.group(1)!;
    }
    return clean;
  }


  // ── Mechanic Tags (AI Recommendation) ────────────────────────────────────

  /// Returns true if at least one card in the DB already has mechanic tags.
  /// Used by [TagInitializationService] to skip re-initialization.
  Future<bool> hasMechanicTags() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM cards WHERE mechanicTags IS NOT NULL AND mechanicTags != ""',
    );
    return (result.first['cnt'] as int? ?? 0) > 0;
  }

  /// Update the mechanic tags for a single card.
  Future<void> updateCardMechanicTags(String cardId, String tagsString) async {
    final db = await database;
    await db.update(
      'cards',
      {'mechanicTags': tagsString},
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  /// Bulk-update mechanic tags for many cards at once.
  /// [tagMap] maps cardId → comma-separated tag string.
  Future<void> bulkUpdateMechanicTags(Map<String, String> tagMap) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in tagMap.entries) {
      batch.update(
        'cards',
        {'mechanicTags': entry.value},
        where: 'id = ?',
        whereArgs: [entry.key],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Load all cards with their mechanic tags populated.
  Future<List<VgCard>> getCardsWithTags() async {
    final db = await database;
    final maps = await db.query('cards');
    return maps.map((m) => VgCard.fromJson(m)).toList();
  }

  // ── Decks ─────────────────────────────────────────────────────────────

  /// Save (insert or replace) a full deck with its ride line and main cards.
  Future<void> saveDeck({
    required String deckId,
    required String name,
    required String? nation,
    required List<Map<String, dynamic>> rideLineSlots,
    // [{cardId, grade}] — grade -1 for unset slots
    required List<Map<String, dynamic>> mainCards,
    // [{cardId, quantity}]
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // Upsert deck row
      await txn.insert(
        'decks',
        {
          'id': deckId,
          'name': name,
          'nation': nation,
          'createdAt': now,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // If updating, preserve createdAt
      await txn.rawUpdate(
        'UPDATE decks SET name = ?, nation = ?, updatedAt = ? WHERE id = ?',
        [name, nation, now, deckId],
      );

      // Delete old cards for this deck
      await txn.delete('deck_cards', where: 'deckId = ?', whereArgs: [deckId]);

      // Insert ride line slots
      for (final slot in rideLineSlots) {
        final cardId = slot['cardId'] as String?;
        final grade = slot['grade'] as int;
        if (cardId != null && cardId.isNotEmpty) {
          await txn.insert('deck_cards', {
            'deckId': deckId,
            'cardId': cardId,
            'quantity': 1,
            'isRideLine': 1,
            'rideLineGrade': grade,
          });
        }
      }

      // Insert main deck cards
      for (final entry in mainCards) {
        await txn.insert('deck_cards', {
          'deckId': deckId,
          'cardId': entry['cardId'] as String,
          'quantity': entry['quantity'] as int,
          'isRideLine': 0,
          'rideLineGrade': -1,
        });
      }
    });
  }

  /// Update only the deck's name without touching cards.
  Future<void> renameDeck(String deckId, String newName) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'decks',
      {'name': newName, 'updatedAt': now},
      where: 'id = ?',
      whereArgs: [deckId],
    );
  }

  /// Load all deck summaries (without card details).
  Future<List<Map<String, dynamic>>> getAllDecks() async {
    final db = await database;
    return db.query('decks', orderBy: 'updatedAt DESC');
  }

  /// Load card rows for a specific deck.
  Future<List<Map<String, dynamic>>> getDeckCards(String deckId) async {
    final db = await database;
    return db.query(
      'deck_cards',
      where: 'deckId = ?',
      whereArgs: [deckId],
    );
  }

  /// Delete a deck and all its cards (CASCADE handles deck_cards).
  Future<void> deleteDeck(String deckId) async {
    final db = await database;
    await db.delete('decks', where: 'id = ?', whereArgs: [deckId]);
    // Fallback in case FOREIGN KEY CASCADE is not enabled
    await db.delete('deck_cards', where: 'deckId = ?', whereArgs: [deckId]);
  }

  /// Load a deck's card details by joining with cards table.
  Future<Map<String, dynamic>> loadFullDeck(String deckId) async {
    final db = await database;

    final deckRows = await db.query('decks', where: 'id = ?', whereArgs: [deckId]);
    if (deckRows.isEmpty) return {};

    final deck = deckRows.first;
    final cardRows = await db.query('deck_cards', where: 'deckId = ?', whereArgs: [deckId]);

    final List<Map<String, dynamic>> rideLineSlots = [];
    final List<Map<String, dynamic>> mainCards = [];

    for (final row in cardRows) {
      final isRideLine = (row['isRideLine'] as int) == 1;
      final cardRows2 = await db.query('cards', where: 'id = ?', whereArgs: [row['cardId']]);
      if (cardRows2.isEmpty) continue;

      final cardData = cardRows2.first;
      if (isRideLine) {
        rideLineSlots.add({
          'grade': row['rideLineGrade'],
          'card': cardData,
        });
      } else {
        mainCards.add({
          'card': cardData,
          'quantity': row['quantity'],
        });
      }
    }

    return {
      'id': deck['id'],
      'name': deck['name'],
      'nation': deck['nation'],
      'createdAt': deck['createdAt'],
      'updatedAt': deck['updatedAt'],
      'rideLineSlots': rideLineSlots,
      'mainCards': mainCards,
    };
  }

  /// Get only the counts per deck (for summary display).
  Future<Map<String, int>> getDeckCardCounts() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT deckId,
             SUM(CASE WHEN isRideLine = 0 THEN quantity ELSE 0 END) as mainCount,
             SUM(CASE WHEN isRideLine = 1 THEN 1 ELSE 0 END) as rideCount
      FROM deck_cards
      GROUP BY deckId
    ''');
    final result = <String, int>{};
    for (final row in rows) {
      result[row['deckId'] as String] =
          ((row['mainCount'] as int?) ?? 0);
    }
    return result;
  }
}
