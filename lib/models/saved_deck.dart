import 'vg_card.dart';

/// Represents a saved deck with its ride line and main deck cards.
class SavedDeck {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;

  /// Grade 0–3 ride line slots. null = not yet chosen.
  final Map<int, VgCard?> rideLineSlots; // key: grade (0,1,2,3)

  /// Main deck cards: cardId → {card, quantity}
  final List<SavedDeckEntry> mainCards;

  SavedDeck({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    Map<int, VgCard?>? rideLineSlots,
    List<SavedDeckEntry>? mainCards,
  })  : rideLineSlots = rideLineSlots ?? {0: null, 1: null, 2: null, 3: null},
        mainCards = mainCards ?? [];

  /// Derived nation from ride line (G3 → G2 → G1 → G0)
  String? get nation {
    for (int g = 3; g >= 0; g--) {
      final card = rideLineSlots[g];
      if (card != null && card.hasNation) return card.nation.trim();
    }
    return null;
  }

  bool get isRideLineComplete =>
      rideLineSlots[0] != null &&
      rideLineSlots[1] != null &&
      rideLineSlots[2] != null &&
      rideLineSlots[3] != null;

  int get totalMainCards =>
      mainCards.fold(0, (sum, e) => sum + e.quantity);

  int get triggerCount => mainCards
      .where((e) => e.card.isTriggerUnit)
      .fold(0, (sum, e) => sum + e.quantity);

  int get healTriggerCount => mainCards
      .where((e) => e.card.isHealTrigger)
      .fold(0, (sum, e) => sum + e.quantity);

  int get overTriggerCount => mainCards
      .where((e) => e.card.isOverTrigger)
      .fold(0, (sum, e) => sum + e.quantity);

  bool get isComplete => isRideLineComplete && totalMainCards == 50;

  /// Create a deep-mutable copy of this deck.
  SavedDeck copyWith({
    String? name,
    Map<int, VgCard?>? rideLineSlots,
    List<SavedDeckEntry>? mainCards,
    DateTime? updatedAt,
  }) {
    return SavedDeck(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      rideLineSlots: rideLineSlots != null
          ? Map<int, VgCard?>.from(rideLineSlots)
          : Map<int, VgCard?>.from(this.rideLineSlots),
      mainCards: mainCards ?? List<SavedDeckEntry>.from(this.mainCards),
    );
  }

  /// Serialise for DB insert.
  List<Map<String, dynamic>> get rideLineSlotsForDb {
    return [0, 1, 2, 3].map((g) {
      return {
        'cardId': rideLineSlots[g]?.id ?? '',
        'grade': g,
      };
    }).toList();
  }

  List<Map<String, dynamic>> get mainCardsForDb {
    return mainCards.map((e) {
      return {'cardId': e.card.id, 'quantity': e.quantity};
    }).toList();
  }
}

class SavedDeckEntry {
  final VgCard card;
  final int quantity;

  const SavedDeckEntry({required this.card, required this.quantity});

  SavedDeckEntry copyWith({int? quantity}) =>
      SavedDeckEntry(card: card, quantity: quantity ?? this.quantity);
}
