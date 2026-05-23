import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_recommendation.dart';
import '../models/deck_context.dart';
import '../models/saved_deck.dart';
import '../models/vg_card.dart';
import '../services/card_similarity_engine.dart';
import 'card_provider.dart';

// ── Input state ──────────────────────────────────────────────────────────────

/// Holds the target card and optional deck context for a recommendation query.
class RecommendationInput {
  final VgCard targetCard;
  final DeckContext? deckContext;
  final String? regulationFilter; // null = all formats
  final String? nationFilter;     // null = all nations

  const RecommendationInput({
    required this.targetCard,
    this.deckContext,
    this.regulationFilter,
    this.nationFilter,
  });

  RecommendationInput copyWith({
    VgCard? targetCard,
    Object? deckContext = _sentinel,
    Object? regulationFilter = _sentinel,
    Object? nationFilter = _sentinel,
  }) {
    return RecommendationInput(
      targetCard: targetCard ?? this.targetCard,
      deckContext:
          deckContext == _sentinel ? this.deckContext : deckContext as DeckContext?,
      regulationFilter: regulationFilter == _sentinel
          ? this.regulationFilter
          : regulationFilter as String?,
      nationFilter:
          nationFilter == _sentinel ? this.nationFilter : nationFilter as String?,
    );
  }
}

const _sentinel = Object();

// ── Filter state ─────────────────────────────────────────────────────────────

class RecommendationInputNotifier extends Notifier<RecommendationInput?> {
  @override
  RecommendationInput? build() => null;

  void setInput(VgCard targetCard, {DeckContext? deckContext}) {
    state = RecommendationInput(
      targetCard: targetCard,
      deckContext: deckContext,
    );
  }

  void updateRegulationFilter(String? format) {
    if (state == null) return;
    state = state!.copyWith(regulationFilter: format);
  }

  void updateNationFilter(String? nation) {
    if (state == null) return;
    state = state!.copyWith(nationFilter: nation);
  }

  void updateDeckContext(DeckContext? ctx) {
    if (state == null) return;
    state = state!.copyWith(deckContext: ctx);
  }

  void clear() => state = null;
}

final recommendationInputProvider =
    NotifierProvider<RecommendationInputNotifier, RecommendationInput?>(
  RecommendationInputNotifier.new,
);

// ── Result computation ───────────────────────────────────────────────────────

/// Computes recommendation results reactively whenever the input changes.
/// Returns at most [maxResults] recommendations sorted by score descending.
const int maxResults = 15;

final recommendationResultProvider =
    FutureProvider.family<List<CardRecommendation>, RecommendationInput>(
  (ref, input) async {
    // Load all cards from the already-loaded card list (no extra DB hit)
    final cardsAsync = ref.watch(cardListProvider);
    final allCards = cardsAsync.valueOrNull ?? [];

    if (allCards.isEmpty) return [];

    final target = input.targetCard;
    final targetGrade = int.tryParse(target.grade.trim());

    // Step 1: Filter candidates
    final candidates = allCards.where((c) {
      if (c.id == target.id) return false;

      // Grade filter: same grade only
      final cGrade = int.tryParse(c.grade.trim());
      if (targetGrade != null && cGrade != null && (cGrade - targetGrade).abs() > 1) {
        return false;
      }

      // Nation filter (user-selected)
      if (input.nationFilter != null && input.nationFilter!.isNotEmpty) {
        final cn = c.nation.trim().toLowerCase();
        if (cn.isNotEmpty && cn != '-' && cn != input.nationFilter!.toLowerCase()) {
          return false;
        }
      }

      // Regulation filter (user-selected)
      if (input.regulationFilter != null && input.regulationFilter!.isNotEmpty) {
        final cr = c.regulation.trim().toLowerCase();
        // Allow empty regulation (unknown) through — per design decision
        if (cr.isNotEmpty && cr != '-' &&
            cr != input.regulationFilter!.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();

    // Step 2: Score all candidates using resolved tags
    final targetWithTags = _withResolvedTags(target);

    final recommendations = candidates.map((candidate) {
      final c = _withResolvedTags(candidate);
      return CardSimilarityEngine.buildRecommendation(
        targetWithTags,
        c,
        input.deckContext,
      );
    }).toList();

    // Step 3: Sort by score descending
    recommendations.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));

    return recommendations.take(maxResults).toList();
  },
);

/// Helper: return a copy of [card] with resolvedTags injected as mechanicTags.
VgCard _withResolvedTags(VgCard card) {
  final tags = card.resolvedTags;
  if (tags == card.mechanicTags) return card;
  // Rebuild with resolved tags so CardSimilarityEngine uses them
  return VgCard(
    id: card.id,
    name: card.name,
    imageUrl: card.imageUrl,
    unitType: card.unitType,
    clan: card.clan,
    nation: card.nation,
    race: card.race,
    grade: card.grade,
    power: card.power,
    critical: card.critical,
    shield: card.shield,
    skill: card.skill,
    trigger: card.trigger,
    effectText: card.effectText,
    setName: card.setName,
    rarity: card.rarity,
    regulation: card.regulation,
    illustrator: card.illustrator,
    flavorText: card.flavorText,
    mechanicTags: tags,
  );
}

// ── Deck context builder ─────────────────────────────────────────────────────

/// Build a [DeckContext] from a [SavedDeck] to pass into recommendations.
DeckContext deckContextFromSavedDeck(SavedDeck deck) {
  final existingIds = deck.mainCards.map((e) => e.card.id).toList();
  final gradeCounts = <int, int>{};
  for (final entry in deck.mainCards) {
    final g = int.tryParse(entry.card.grade.trim()) ?? -1;
    if (g >= 0) gradeCounts[g] = (gradeCounts[g] ?? 0) + entry.quantity;
  }
  return DeckContext(
    deckId: deck.id,
    deckName: deck.name,
    deckNation: deck.nation,
    existingCardIds: existingIds,
    gradeCounts: gradeCounts,
  );
}

// ── Available regulation formats (derived from card list) ────────────────────

final availableRegulationsProvider = Provider<AsyncValue<List<String>>>((ref) {
  final cardsAsync = ref.watch(cardListProvider);
  return cardsAsync.whenData((cards) {
    final regs = cards
        .map((c) => c.regulation.trim())
        .where((r) => r.isNotEmpty && r != '-')
        .toSet()
        .toList()
      ..sort();
    return regs;
  });
});
