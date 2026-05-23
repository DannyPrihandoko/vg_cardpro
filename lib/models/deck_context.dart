/// Represents the context of the user's active deck when requesting
/// card replacement recommendations. All fields are optional — if null,
/// the corresponding scoring dimension uses a neutral value.
class DeckContext {
  /// Internal deck ID (used for display/tracking only).
  final String? deckId;

  /// The name of the deck (for display).
  final String? deckName;

  /// The nation of the deck (e.g. "dragon empire", "dark states").
  /// Derived from the ride line's Grade 3 card.
  final String? deckNation;

  /// The regulation format (e.g. "D-Standard", "Premium").
  /// If null, regulation matching is skipped (neutral score).
  final String? regulationFormat;

  /// IDs of all cards currently in the main deck (excluding ride line).
  final List<String> existingCardIds;

  /// How many of each grade are already in the main deck.
  /// Key = grade (0,1,2,3,4), value = total quantity.
  final Map<int, int> gradeCounts;

  const DeckContext({
    this.deckId,
    this.deckName,
    this.deckNation,
    this.regulationFormat,
    this.existingCardIds = const [],
    this.gradeCounts = const {},
  });

  /// True if a card with [cardId] is already in this deck.
  bool containsCard(String cardId) => existingCardIds.contains(cardId);

  /// How many cards of the given [grade] are in the deck.
  int countForGrade(int grade) => gradeCounts[grade] ?? 0;

  /// A deck context with no information (all neutral).
  static const empty = DeckContext();
}
