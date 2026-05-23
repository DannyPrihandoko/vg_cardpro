import 'package:flutter/foundation.dart';
import '../models/mechanic_tag.dart';
import '../models/vg_card.dart';
import 'database_service.dart';
import 'mechanic_tag_parser.dart';

/// One-time service that parses and persists mechanic tags for all cards.
///
/// This runs in the background when cards are first loaded (or after a DB
/// upgrade to version 5). Progress is tracked via [onProgress] callback.
class TagInitializationService {
  TagInitializationService._();

  /// Check if tags have already been initialized (any card has a non-empty tag).
  static Future<bool> isInitialized(DatabaseService db) async {
    return await db.hasMechanicTags();
  }

  /// Parse and save mechanic tags for all [cards].
  ///
  /// Runs in a background isolate via [compute] to keep the UI responsive.
  /// [onProgress] is called with (current, total) as cards are processed.
  static Future<void> initializeAll(
    DatabaseService db,
    List<VgCard> cards, {
    void Function(int current, int total)? onProgress,
  }) async {
    debugPrint('[TagInit] Starting tag initialization for ${cards.length} cards...');

    // Parse tags in a background isolate to avoid blocking the UI
    final tagMap = await compute(_parseAllTags, cards);

    // Write to DB in batches
    await db.bulkUpdateMechanicTags(tagMap);

    debugPrint('[TagInit] Done. Initialized tags for ${tagMap.length} cards.');
  }

  /// Top-level function (required for compute isolate) — parses tags for all cards.
  static Map<String, String> _parseAllTags(List<VgCard> cards) {
    final result = <String, String>{};
    for (final card in cards) {
      final tags = MechanicTagParser.parse(
        card.effectText,
        triggerField: card.trigger,
      );
      result[card.id] = MechanicTagCodec.encode(tags);
    }
    return result;
  }
}
