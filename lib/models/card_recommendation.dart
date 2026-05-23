import 'mechanic_tag.dart';
import 'vg_card.dart';

/// Represents a single card recommended as a replacement for a target card.
class CardRecommendation {
  /// The recommended card itself.
  final VgCard card;

  /// Normalized similarity score between 0.0 (no match) and 1.0 (perfect match).
  final double similarityScore;

  /// Tags that both the target card and this card share.
  final List<MechanicTag> matchedTags;

  /// Human-readable reasons explaining why this card was recommended.
  /// e.g. ["Same grade (2)", "Shares: Draw Engine, Power Booster", "Compatible nation"]
  final List<String> reasons;

  /// True if this card already exists in the user's active deck.
  final bool isInDeck;

  /// True if the regulation format matches the target card's format.
  final bool regulationMatch;

  const CardRecommendation({
    required this.card,
    required this.similarityScore,
    required this.matchedTags,
    required this.reasons,
    required this.isInDeck,
    required this.regulationMatch,
  });

  /// Score as a percentage string, e.g. "82%"
  String get scorePercent => '${(similarityScore * 100).round()}%';

  /// Score label based on threshold
  String get scoreLabel {
    if (similarityScore >= 0.8) return 'Excellent';
    if (similarityScore >= 0.6) return 'Good';
    if (similarityScore >= 0.4) return 'Moderate';
    return 'Low';
  }
}
