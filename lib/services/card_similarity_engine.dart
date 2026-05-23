import '../models/card_recommendation.dart';
import '../models/deck_context.dart';
import '../models/mechanic_tag.dart';
import '../models/vg_card.dart';

/// Core AI engine that computes similarity scores between a target card
/// and candidate replacement cards. Runs fully on-device with no external APIs.
///
/// ## Scoring formula (weights sum to 1.0):
/// | Dimension              | Weight |
/// |------------------------|--------|
/// | Mechanic tag overlap   |  0.40  |
/// | Grade match            |  0.20  |
/// | Nation compatibility   |  0.15  |
/// | Regulation match       |  0.15  |
/// | Power/Shield match     |  0.10  |
///
/// Deck-context bonuses (clamped, never exceed 1.0):
/// - +0.05 if the card is NOT already in the deck (encourage alternatives)
/// - +0.03 if the deck needs more cards of this grade
class CardSimilarityEngine {
  CardSimilarityEngine._();

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Compute a similarity score [0.0, 1.0] between [target] and [candidate].
  ///
  /// [deckContext] is optional — if null, deck-aware bonuses are skipped.
  static double computeScore(
    VgCard target,
    VgCard candidate,
    DeckContext? deckContext,
  ) {
    // Exclude the card from recommending itself
    if (target.id == candidate.id) return 0.0;

    final tagScore       = _tagScore(target.mechanicTags, candidate.mechanicTags);
    final gradeScore     = _gradeScore(target.grade, candidate.grade);
    final nationScore    = _nationScore(target.nation, candidate.nation);
    final regulationScore = _regulationScore(target.regulation, candidate.regulation);
    final statScore      = _statScore(target.power, candidate.power,
                                       target.shield, candidate.shield);

    double score = (tagScore       * 0.40) +
                   (gradeScore     * 0.20) +
                   (nationScore    * 0.15) +
                   (regulationScore * 0.15) +
                   (statScore      * 0.10);

    // Deck-context bonuses
    if (deckContext != null) {
      if (!deckContext.containsCard(candidate.id)) score += 0.05;
      final grade = int.tryParse(candidate.grade.trim()) ?? -1;
      if (grade >= 0 && deckContext.countForGrade(grade) < 12) score += 0.03;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Generate a full [CardRecommendation] from [target] vs [candidate].
  static CardRecommendation buildRecommendation(
    VgCard target,
    VgCard candidate,
    DeckContext? deckContext,
  ) {
    final score      = computeScore(target, candidate, deckContext);
    final matched    = _matchedTags(target.mechanicTags, candidate.mechanicTags);
    final reasons    = _buildReasons(target, candidate, matched, deckContext);
    final inDeck     = deckContext?.containsCard(candidate.id) ?? false;
    final regMatch   = _regulationScore(target.regulation, candidate.regulation) >= 0.9;

    return CardRecommendation(
      card: candidate,
      similarityScore: score,
      matchedTags: matched,
      reasons: reasons,
      isInDeck: inDeck,
      regulationMatch: regMatch,
    );
  }

  // ── Scoring dimensions ────────────────────────────────────────────────────

  /// Jaccard similarity: |A ∩ B| / |A ∪ B|
  static double _tagScore(List<MechanicTag> a, List<MechanicTag> b) {
    if (a.isEmpty && b.isEmpty) return 0.5; // both have no tags: neutral
    if (a.isEmpty || b.isEmpty) return 0.0;

    final setA = a.toSet();
    final setB = b.toSet();
    final intersection = setA.intersection(setB).length;
    final union        = setA.union(setB).length;
    return union == 0 ? 0.0 : intersection / union;
  }

  static double _gradeScore(String gradeA, String gradeB) {
    final a = int.tryParse(gradeA.trim());
    final b = int.tryParse(gradeB.trim());
    if (a == null || b == null) return 0.3; // unknown → neutral-low
    final diff = (a - b).abs();
    if (diff == 0) return 1.0;
    if (diff == 1) return 0.4;
    return 0.0;
  }

  static double _nationScore(String nationA, String nationB) {
    final a = nationA.trim().toLowerCase();
    final b = nationB.trim().toLowerCase();
    final isEmpty = (s) => s.isEmpty || s == '-';

    if (isEmpty(a) || isEmpty(b)) return 0.7; // no-nation = compatible
    if (a == b) return 1.0;
    return 0.0;
  }

  static double _regulationScore(String regA, String regB) {
    final a = regA.trim().toLowerCase();
    final b = regB.trim().toLowerCase();
    final isEmpty = (s) => s.isEmpty || s == '-' || s == 'unknown';

    if (isEmpty(a) || isEmpty(b)) return 0.5; // unknown → neutral
    if (a == b) return 1.0;
    return 0.0;
  }

  static double _statScore(
      String powerA, String powerB, String shieldA, String shieldB) {
    final pa = int.tryParse(powerA.replaceAll(',', '').trim()) ?? 0;
    final pb = int.tryParse(powerB.replaceAll(',', '').trim()) ?? 0;
    final sa = int.tryParse(shieldA.replaceAll(',', '').replaceAll('-', '0').trim()) ?? 0;
    final sb = int.tryParse(shieldB.replaceAll(',', '').replaceAll('-', '0').trim()) ?? 0;

    final powerSim  = pa == 0 && pb == 0
        ? 0.5
        : 1.0 - ((pa - pb).abs() / 20000.0).clamp(0.0, 1.0);
    final shieldSim = sa == 0 && sb == 0
        ? 0.5
        : 1.0 - ((sa - sb).abs() / 10000.0).clamp(0.0, 1.0);

    return (powerSim + shieldSim) / 2.0;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<MechanicTag> _matchedTags(
      List<MechanicTag> a, List<MechanicTag> b) {
    return a.toSet().intersection(b.toSet()).toList();
  }

  static List<String> _buildReasons(
    VgCard target,
    VgCard candidate,
    List<MechanicTag> matched,
    DeckContext? deckContext,
  ) {
    final reasons = <String>[];

    // Grade
    final tg = int.tryParse(target.grade.trim());
    final cg = int.tryParse(candidate.grade.trim());
    if (tg != null && cg != null) {
      if (tg == cg) {
        reasons.add('Same grade (${candidate.grade})');
      } else {
        reasons.add('Similar grade (G${candidate.grade} vs G${target.grade})');
      }
    }

    // Mechanic tags
    if (matched.isNotEmpty) {
      final tagNames = matched.map((t) => t.label).join(', ');
      reasons.add('Shares: $tagNames');
    }

    // Nation
    final tn = target.nation.trim().toLowerCase();
    final cn = candidate.nation.trim().toLowerCase();
    if (tn.isNotEmpty && cn.isNotEmpty && tn != '-' && cn != '-') {
      if (tn == cn) {
        reasons.add('Same nation (${candidate.nation})');
      }
    } else if (cn.isEmpty || cn == '-') {
      reasons.add('No-nation card (compatible with any deck)');
    }

    // Regulation
    final tr = target.regulation.trim().toLowerCase();
    final cr = candidate.regulation.trim().toLowerCase();
    if (tr.isNotEmpty && cr.isNotEmpty && tr == cr) {
      reasons.add('Same regulation format (${candidate.regulation})');
    } else if (cr.isEmpty || cr == '-') {
      reasons.add('Regulation: Unknown');
    }

    // Deck context
    if (deckContext != null && deckContext.containsCard(candidate.id)) {
      reasons.add('Already in your deck');
    }

    return reasons;
  }
}
