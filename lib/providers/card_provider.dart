import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vg_card.dart';
import '../models/saved_deck.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/tag_initialization_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Menggunakan AsyncNotifier untuk menerapkan arsitektur Offline-First
class CardListNotifier extends AsyncNotifier<List<VgCard>> {
  @override
  Future<List<VgCard>> build() async {
    // 1. Try load from local database first
    final dbService = ref.read(databaseServiceProvider);
    final localCards = await dbService.getCards();

    // 2. If local DB is empty, fetch from JSON asset
    if (localCards.isEmpty) {
      final cards = await _fetchAndCacheCards();
      _initTagsInBackground(cards);
      return cards;
    }

    // 3. Local DB has data — return immediately, sync in background
    _syncBackground();
    _initTagsInBackground(localCards);
    return localCards;
  }

  /// Initialize mechanic tags for all cards in the background (once).
  void _initTagsInBackground(List<VgCard> cards) {
    final dbService = ref.read(databaseServiceProvider);
    TagInitializationService.isInitialized(dbService).then((alreadyDone) {
      if (!alreadyDone) {
        debugPrint('[CardProvider] Tag init needed — starting background parse...');
        TagInitializationService.initializeAll(dbService, cards);
      }
    });
  }

  Future<void> _syncBackground() async {
    try {
      final newCards = await _fetchAndCacheCards();
      // Update state Riverpod dengan data terbaru secara reaktif
      state = AsyncData(newCards);
    } catch (e) {
      // Jika background sync gagal (misal tidak ada internet), 
      // kita diamkan saja dan biarkan state menggunakan data lokal (offline).
      // Anda bisa menambahkan logging di sini.
      debugPrint('Background sync failed: $e');
    }
  }

  Future<List<VgCard>> _fetchAndCacheCards() async {
    final apiService = ref.read(apiServiceProvider);
    final dbService = ref.read(databaseServiceProvider);

    // Ambil dari server (dummy untuk saat ini)
    final remoteCards = await apiService.fetchCards();
    
    // Simpan ke local DB
    if (remoteCards.isNotEmpty) {
      await dbService.insertCards(remoteCards);
    }
    
    return remoteCards;
  }
  
  // Method untuk interaksi User (misal pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncLoading(); // Set UI ke loading sementara fetch
    try {
      final newCards = await _fetchAndCacheCards();
      state = AsyncData(newCards);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final cardListProvider = AsyncNotifierProvider<CardListNotifier, List<VgCard>>(() {
  return CardListNotifier();
});

// Notifier untuk menyimpan teks pencarian user
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// Notifier untuk menyimpan filter nation yang dipilih
class NationFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectNation(String? nation) {
    state = nation;
  }
}

final nationFilterProvider = NotifierProvider<NationFilterNotifier, String?>(() {
  return NationFilterNotifier();
});

// Notifier untuk menyimpan teks pencarian global (di home)
class GlobalSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final globalSearchQueryProvider = NotifierProvider<GlobalSearchQueryNotifier, String>(() {
  return GlobalSearchQueryNotifier();
});

// Provider turunan untuk menghasilkan list kartu yang sudah di-filter berdasarkan setName dan query
final filteredCardsProvider = Provider.family<AsyncValue<List<VgCard>>, String>((ref, setName) {
  final cardsAsync = ref.watch(cardListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return cardsAsync.whenData((cards) {
    var filtered = cards.where((card) => card.setName == setName).toList();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((card) => card.name.toLowerCase().contains(query))
          .toList();
    }
    return filtered;
  });
});

// Provider global search: filter berdasarkan nama kartu dan/atau nation
final globalFilteredCardsProvider = Provider<AsyncValue<List<VgCard>>>((ref) {
  final cardsAsync = ref.watch(cardListProvider);
  final query = ref.watch(globalSearchQueryProvider).toLowerCase();
  final selectedNation = ref.watch(nationFilterProvider);

  return cardsAsync.whenData((cards) {
    var filtered = cards;

    if (selectedNation != null && selectedNation.isNotEmpty) {
      filtered = filtered.where((card) => card.nation.contains(selectedNation)).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered
          .where((card) => card.name.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  });
});

// Provider to extract unique sets from the card list
final setsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final cardsAsync = ref.watch(cardListProvider);
  return cardsAsync.whenData((cards) {
    final sets = cards
        .map((c) => c.setName)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    sets.sort();
    return sets;
  });
});

// Provider to extract unique nations from the card list
final nationsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final cardsAsync = ref.watch(cardListProvider);
  return cardsAsync.whenData((cards) {
    final nations = cards
        .map((c) => c.nation)
        .where((n) => n.isNotEmpty && n != '-')
        .toSet()
        .toList();
    nations.sort();
    return nations;
  });
});

// ── DECK BUILDER STATE AND PROVIDERS ───────────────────────────────

class DeckItem {
  final VgCard card;
  final int quantity;
  const DeckItem({required this.card, required this.quantity});
}

// ── RIDE LINE ─────────────────────────────────────────────────────────────

/// Represents the 4-slot ride line (Grade 0 → 1 → 2 → 3)
class RideLine {
  final VgCard? grade0;
  final VgCard? grade1;
  final VgCard? grade2;
  final VgCard? grade3;

  const RideLine({
    this.grade0,
    this.grade1,
    this.grade2,
    this.grade3,
  });

  VgCard? slotForGrade(int grade) {
    switch (grade) {
      case 0: return grade0;
      case 1: return grade1;
      case 2: return grade2;
      case 3: return grade3;
      default: return null;
    }
  }

  /// The nation determined by the ride line (taken from the Grade 3 card, falling back up).
  String? get nation {
    final ref = grade3 ?? grade2 ?? grade1 ?? grade0;
    if (ref == null) return null;
    if (!ref.hasNation) return null;
    return ref.nation.trim();
  }

  bool get isComplete =>
      grade0 != null && grade1 != null && grade2 != null && grade3 != null;

  RideLine copyWith({
    Object? grade0 = _sentinel,
    Object? grade1 = _sentinel,
    Object? grade2 = _sentinel,
    Object? grade3 = _sentinel,
  }) {
    return RideLine(
      grade0: grade0 == _sentinel ? this.grade0 : grade0 as VgCard?,
      grade1: grade1 == _sentinel ? this.grade1 : grade1 as VgCard?,
      grade2: grade2 == _sentinel ? this.grade2 : grade2 as VgCard?,
      grade3: grade3 == _sentinel ? this.grade3 : grade3 as VgCard?,
    );
  }
}

const _sentinel = Object();

class RideLineNotifier extends Notifier<RideLine> {
  @override
  RideLine build() => const RideLine();

  void setSlot(int grade, VgCard? card) {
    switch (grade) {
      case 0:
        state = state.copyWith(grade0: card);
        break;
      case 1:
        state = state.copyWith(grade1: card);
        break;
      case 2:
        state = state.copyWith(grade2: card);
        break;
      case 3:
        state = state.copyWith(grade3: card);
        break;
    }
  }

  void clearSlot(int grade) => setSlot(grade, null);

  void clearAll() {
    state = const RideLine();
  }
}

final rideLineProvider = NotifierProvider<RideLineNotifier, RideLine>(() {
  return RideLineNotifier();
});

/// Derived: the allowed nation for the deck (from ride line). Null = no ride line set yet.
final deckAllowedNationProvider = Provider<String?>((ref) {
  return ref.watch(rideLineProvider).nation;
});

// ── DECK STATS ────────────────────────────────────────────────────────────

class DeckStats {
  final int totalCards;
  final int triggerCount;
  final int healTriggerCount;
  final int overTriggerCount;

  const DeckStats({
    required this.totalCards,
    required this.triggerCount,
    required this.healTriggerCount,
    required this.overTriggerCount,
  });

  bool get isFull => totalCards >= 50;
  bool get triggerLimitReached => triggerCount >= 16;
  bool get healLimitReached => healTriggerCount >= 4;
  bool get overLimitReached => overTriggerCount >= 1;
}

final deckStatsProvider = Provider<DeckStats>((ref) {
  final deck = ref.watch(deckProvider);
  int total = 0, triggers = 0, heals = 0, overs = 0;
  for (final item in deck) {
    final qty = item.quantity;
    total += qty;
    if (item.card.isTriggerUnit) {
      triggers += qty;
      if (item.card.isHealTrigger) heals += qty;
      if (item.card.isOverTrigger) overs += qty;
    }
  }
  return DeckStats(
    totalCards: total,
    triggerCount: triggers,
    healTriggerCount: heals,
    overTriggerCount: overs,
  );
});

// ── DECK NOTIFIER ─────────────────────────────────────────────────────────

class DeckNotifier extends Notifier<List<DeckItem>> {
  @override
  List<DeckItem> build() => [];

  int get totalCardCount {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }

  int get _triggerCount {
    return state.fold(0, (sum, item) {
      return sum + (item.card.isTriggerUnit ? item.quantity : 0);
    });
  }

  int get _healTriggerCount {
    return state.fold(0, (sum, item) {
      return sum + (item.card.isHealTrigger ? item.quantity : 0);
    });
  }

  int get _overTriggerCount {
    return state.fold(0, (sum, item) {
      return sum + (item.card.isOverTrigger ? item.quantity : 0);
    });
  }

  /// Returns an error string if [card] cannot be added, or null on success.
  String? addToDeck(VgCard card, {String? allowedNation}) {
    // Rule: Max 50 cards total
    if (totalCardCount >= 50) {
      return 'Deck is already full (maximum 50 cards)!';
    }

    // Rule: Nation compatibility
    if (allowedNation != null && allowedNation.isNotEmpty) {
      if (card.hasNation && card.nation.trim() != allowedNation) {
        return "Only $allowedNation cards (or no-nation cards) can be added to this deck!";
      }
    }

    // Rule: Trigger limits (check before adding)
    if (card.isTriggerUnit) {
      if (_triggerCount >= 16) {
        return 'Trigger limit reached! Maximum 16 trigger units in a deck.';
      }
      if (card.isHealTrigger && _healTriggerCount >= 4) {
        return 'Heal trigger limit reached! Maximum 4 heal triggers in a deck.';
      }
      if (card.isOverTrigger && _overTriggerCount >= 1) {
        return 'Over trigger limit reached! Maximum 1 over trigger in a deck.';
      }
    }

    // Find existing entry
    final index = state.indexWhere((item) => item.card.id == card.id);
    if (index != -1) {
      final currentQty = state[index].quantity;
      // Rule: Max 4 copies per card
      if (currentQty >= 4) {
        return "You can only have up to 4 copies of '${card.name}'!";
      }
      final updatedList = List<DeckItem>.from(state);
      updatedList[index] = DeckItem(card: card, quantity: currentQty + 1);
      state = updatedList;
    } else {
      state = [...state, DeckItem(card: card, quantity: 1)];
    }
    return null; // Success
  }

  void removeFromDeck(VgCard card) {
    final index = state.indexWhere((item) => item.card.id == card.id);
    if (index != -1) {
      final currentQty = state[index].quantity;
      final updatedList = List<DeckItem>.from(state);
      if (currentQty > 1) {
        updatedList[index] = DeckItem(card: card, quantity: currentQty - 1);
      } else {
        updatedList.removeAt(index);
      }
      state = updatedList;
    }
  }

  void clearDeck() {
    state = [];
  }
}

final deckProvider = NotifierProvider<DeckNotifier, List<DeckItem>>(() {
  return DeckNotifier();
});

final cardCopiesInDeckProvider = Provider.family<int, String>((ref, cardId) {
  final deck = ref.watch(deckProvider);
  final index = deck.indexWhere((item) => item.card.id == cardId);
  return index != -1 ? deck[index].quantity : 0;
});

// ── RIDE LINE FILTERED CARDS ──────────────────────────────────────────────

/// Filtered cards for ride line picker: by grade, and optionally by nation
/// from already-set slots in the ride line.
final rideLinePickerCardsProvider =
    Provider.family<AsyncValue<List<VgCard>>, int>((ref, grade) {
  final cardsAsync = ref.watch(cardListProvider);
  final rideLine = ref.watch(rideLineProvider);

  // Determine allowed nation from already-set slots
  final String? nationFromRideLine = rideLine.nation;

  return cardsAsync.whenData((cards) {
    var filtered = cards.where((c) {
      // Must be a non-trigger unit (ride line cards don't have triggers)
      // And must match the target grade
      final cardGrade = int.tryParse(c.grade.trim()) ?? -1;
      return cardGrade == grade && !c.isTriggerUnit;
    }).toList();

    // Apply nation filter if ride line already has a nation determined
    if (nationFromRideLine != null && nationFromRideLine.isNotEmpty) {
      filtered = filtered.where((c) {
        if (!c.hasNation) return true; // no-nation cards are always allowed
        return c.nation.trim() == nationFromRideLine;
      }).toList();
    }

    return filtered;
  });
});

// ── DECK MANAGER (multi-deck persistence) ─────────────────────────────────

/// Simple unique ID using timestamp + counter
String _generateDeckId() {
  return 'deck_${DateTime.now().millisecondsSinceEpoch}';
}

/// Holds the list of all saved decks loaded from SQLite
class DeckManagerNotifier extends AsyncNotifier<List<SavedDeck>> {
  @override
  Future<List<SavedDeck>> build() async {
    return _loadAllDecks();
  }

  Future<List<SavedDeck>> _loadAllDecks() async {
    final db = ref.read(databaseServiceProvider);
    final rows = await db.getAllDecks();
    final List<SavedDeck> decks = [];

    for (final row in rows) {
      final fullData = await db.loadFullDeck(row['id'] as String);
      if (fullData.isEmpty) continue;

      final rideSlots = <int, VgCard?>{0: null, 1: null, 2: null, 3: null};
      for (final slot in (fullData['rideLineSlots'] as List)) {
        final grade = slot['grade'] as int;
        final cardData = slot['card'] as Map<String, dynamic>;
        rideSlots[grade] = VgCard.fromJson(cardData);
      }

      final mainCards = <SavedDeckEntry>[];
      for (final entry in (fullData['mainCards'] as List)) {
        final cardData = entry['card'] as Map<String, dynamic>;
        mainCards.add(SavedDeckEntry(
          card: VgCard.fromJson(cardData),
          quantity: entry['quantity'] as int,
        ));
      }

      decks.add(SavedDeck(
        id: row['id'] as String,
        name: row['name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updatedAt'] as int),
        rideLineSlots: rideSlots,
        mainCards: mainCards,
      ));
    }
    return decks;
  }

  /// Create a new empty deck and persist it.
  Future<SavedDeck> createDeck(String name) async {
    final db = ref.read(databaseServiceProvider);
    final id = _generateDeckId();
    final now = DateTime.now();
    final deck = SavedDeck(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
    await db.saveDeck(
      deckId: id,
      name: name,
      nation: null,
      rideLineSlots: deck.rideLineSlotsForDb,
      mainCards: [],
    );
    state = AsyncData([deck, ...state.value ?? []]);
    return deck;
  }

  /// Persist (save/update) an existing deck.
  Future<void> saveDeck(SavedDeck deck) async {
    final db = ref.read(databaseServiceProvider);
    await db.saveDeck(
      deckId: deck.id,
      name: deck.name,
      nation: deck.nation,
      rideLineSlots: deck.rideLineSlotsForDb,
      mainCards: deck.mainCardsForDb,
    );
    // Refresh list from DB to get consistent updatedAt
    state = AsyncData(await _loadAllDecks());
  }

  /// Rename a deck in-place.
  Future<void> renameDeck(String deckId, String newName) async {
    final db = ref.read(databaseServiceProvider);
    await db.renameDeck(deckId, newName);
    state = AsyncData(await _loadAllDecks());
  }

  /// Delete a deck permanently.
  Future<void> deleteDeck(String deckId) async {
    final db = ref.read(databaseServiceProvider);
    await db.deleteDeck(deckId);
    final current = List<SavedDeck>.from(state.value ?? []);
    current.removeWhere((d) => d.id == deckId);
    state = AsyncData(current);
  }

  /// Reload all decks from DB.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadAllDecks());
  }
}

final deckManagerProvider =
    AsyncNotifierProvider<DeckManagerNotifier, List<SavedDeck>>(() {
  return DeckManagerNotifier();
});
