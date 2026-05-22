import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/vg_card.dart';
import '../models/saved_deck.dart';
import 'database_service.dart';


/// Service to encode/decode a [SavedDeck] into a shareable text code.
///
/// Format: Base64url-encoded UTF-8 JSON snapshot of the entire deck,
/// including all card data so the receiver can import without a server.
class DeckShareService {
  static const _version = 1;

  /// Encode a [SavedDeck] into a compact Base64url share code.
  static String encode(SavedDeck deck) {
    final rideSlots = <String, dynamic>{};
    deck.rideLineSlots.forEach((grade, card) {
      if (card != null) {
        rideSlots['$grade'] = _cardToMap(card);
      }
    });

    final mainCards = deck.mainCards
        .map((e) => {..._cardToMap(e.card), 'qty': e.quantity})
        .toList();

    final payload = {
      'v': _version,
      'n': deck.name,
      'r': rideSlots,
      'm': mainCards,
    };

    final jsonStr = jsonEncode(payload);
    return base64Url.encode(utf8.encode(jsonStr));
  }

  /// Decode a share code back into a [SavedDeck] snapshot.
  /// Returns null if the code is invalid.
  static SavedDeck? decode(String code) {
    try {
      final normalized = base64Url.normalize(code.trim());
      final jsonStr = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(jsonStr) as Map<String, dynamic>;

      final name = payload['n'] as String? ?? 'Imported Deck';

      // Rebuild ride line slots
      final rideData = payload['r'] as Map<String, dynamic>? ?? {};
      final rideSlots = <int, VgCard?>{0: null, 1: null, 2: null, 3: null};
      rideData.forEach((gradeStr, cardJson) {
        final grade = int.tryParse(gradeStr);
        if (grade != null && cardJson is Map<String, dynamic>) {
          rideSlots[grade] = _cardFromMap(cardJson);
        }
      });

      // Rebuild main cards
      final mainData = payload['m'] as List<dynamic>? ?? [];
      final mainCards = <SavedDeckEntry>[];
      for (final entry in mainData) {
        if (entry is Map<String, dynamic>) {
          final card = _cardFromMap(entry);
          final qty = (entry['qty'] as int?) ?? 1;
          mainCards.add(SavedDeckEntry(card: card, quantity: qty));
        }
      }

      return SavedDeck(
        id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        rideLineSlots: rideSlots,
        mainCards: mainCards,
      );
    } catch (e) {
      debugPrint('DeckShareService.decode error: $e');
      return null;
    }
  }

  /// Generate a human-readable share message.
  static String shareText(SavedDeck deck, String shareCode) {
    final nation = deck.nation ?? 'Unknown';
    final total = deck.totalMainCards;
    return '🃏 VG Deck: "${deck.name}"\n'
        '🏴 Nation: $nation\n'
        '📦 Cards: $total/50\n\n'
        '📋 Import code (paste in VG CardPro → Import Deck):\n$shareCode';
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static Map<String, dynamic> _cardToMap(VgCard c) => {
        'id': c.id,
        'name': c.name,
        'imageUrl': c.imageUrl,
        'unitType': c.unitType,
        'clan': c.clan,
        'nation': c.nation,
        'race': c.race,
        'grade': c.grade,
        'power': c.power,
        'critical': c.critical,
        'shield': c.shield,
        'skill': c.skill,
        'trigger': c.trigger,
        'effectText': c.effectText,
        'setName': c.setName,
        'rarity': c.rarity,
        'regulation': c.regulation,
        'illustrator': c.illustrator,
        'flavorText': c.flavorText,
      };

  static VgCard _cardFromMap(Map<String, dynamic> m) => VgCard.fromJson(m);

  // ── Plain Text Importer ───────────────────────────────────────────────────

  /// Parse copy-pasted plain text vanguard lists.
  /// Format: [qty] [card number or name]
  static Future<TextImportResult> parsePlainText(String text) async {
    final lines = text.split('\n');
    final db = DatabaseService();
    
    final matches = <TextImportMatch>[];
    final skippedLines = <String>[];
    final mainCards = <SavedDeckEntry>[];
    final rideSlots = <int, VgCard?>{0: null, 1: null, 2: null, 3: null};
    
    // Pattern to match quantity: Optional 'x' or '×' or '*' prefix/suffix, e.g. "4 Blaster Blade", "4x Blaster Blade", "4 x Blaster Blade"
    final qtyRegex = RegExp(r'^(\d+)\s*[x×\*]?\s+|^(\d+)\s+');
    
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      
      int qty = 1;
      String cardTerm = line;
      
      final qtyMatch = qtyRegex.firstMatch(line);
      if (qtyMatch != null) {
        final qtyStr = qtyMatch.group(1) ?? qtyMatch.group(2);
        qty = int.tryParse(qtyStr ?? '') ?? 1;
        cardTerm = line.substring(qtyMatch.end).trim();
      }
      
      if (cardTerm.isEmpty) {
        skippedLines.add(line);
        continue;
      }
      
      // Look up card in SQLite
      final card = await db.findCardByNumberOrName(cardTerm);
      if (card != null) {
        matches.add(TextImportMatch(card: card, quantity: qty));
        
        // Auto-fill ride line if it matches the slot, is only a 1-copy card, and slot is empty
        final grade = int.tryParse(card.grade.trim()) ?? -1;
        if (grade >= 0 && grade <= 3 && qty == 1 && rideSlots[grade] == null && !card.isTriggerUnit) {
          rideSlots[grade] = card;
        } else {
          // Check if there is already an entry for this card in main deck to aggregate
          final idx = mainCards.indexWhere((e) => e.card.id == card.id);
          if (idx != -1) {
            mainCards[idx] = SavedDeckEntry(card: card, quantity: mainCards[idx].quantity + qty);
          } else {
            mainCards.add(SavedDeckEntry(card: card, quantity: qty));
          }
        }
      } else {
        skippedLines.add(line);
      }
    }
    
    final deck = SavedDeck(
      id: 'text_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Text Imported Deck',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      rideLineSlots: rideSlots,
      mainCards: mainCards,
    );
    
    return TextImportResult(
      deck: deck,
      matches: matches,
      skippedLines: skippedLines,
    );
  }

  // ── Bushiroad Deck Log Importer ───────────────────────────────────────────

  /// Fetch and parse a deck from the official Bushiroad Deck Log site.
  /// Supports raw 5-digit codes (e.g. 4DWCZ) or full URLs.
  static Future<DeckLogImportResult?> importFromDeckLog(String input) async {
    // 1. Extract 5-character code
    final codeRegex = RegExp(r'(?:view/|code=)?([A-Z0-9]{5})', caseSensitive: false);
    final match = codeRegex.firstMatch(input.trim());
    if (match == null) return null;
    final deckCode = match.group(1)!.toUpperCase();

    // Determine primary locale subroute to hit (app-ja for Japanese URL views)
    final isJaInput = input.toLowerCase().contains('/ja/') || input.toLowerCase().contains('decklog.bushiroad.com');
    final primaryPath = isJaInput ? 'app-ja' : 'app';
    final fallbackPath = isJaInput ? 'app' : 'app-ja';

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    
    Map<String, dynamic>? deckJson;

    // Retry auto-fallback on paths to be highly resilient to language sub-domains
    final pathsToTry = [primaryPath, fallbackPath];
    for (final path in pathsToTry) {
      final url = 'https://decklog-en.bushiroad.com/system/$path/api/view/$deckCode';
      try {
        final uri = Uri.parse(url);
        final request = await client.postUrl(uri);
        request.headers.set('accept', 'application/json, text/plain, */*');
        request.headers.set('content-type', 'application/json;charset=UTF-8');
        request.headers.set('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        request.headers.set('referer', 'https://decklog-en.bushiroad.com/');
        
        request.write(jsonEncode({}));
        final response = await request.close();
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          if (body.isNotEmpty && body != '[]') {
            final parsed = jsonDecode(body);
            if (parsed is Map<String, dynamic> && parsed.containsKey('list')) {
              deckJson = parsed;
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('DeckShareService.importFromDeckLog error trying $url: $e');
      }
    }

    client.close();

    if (deckJson == null) return null;

    final name = deckJson['title'] as String? ?? 'Deck Log $deckCode';
    
    final matchedCards = <VgCard>[];
    final skippedCardNumbers = <String>[];

    final db = DatabaseService();

    // 1. Rebuild Ride Line (p_list)
    final rideSlots = <int, VgCard?>{0: null, 1: null, 2: null, 3: null};
    final pList = deckJson['p_list'] as List<dynamic>? ?? [];
    
    for (final item in pList) {
      if (item is Map<String, dynamic>) {
        final rawNum = item['card_number'] as String? ?? '';
        final slot = item['slot'] as String? ?? '';
        final gradeStr = item['grade'] as String? ?? '';
        final grade = int.tryParse(gradeStr) ?? -1;

        if (rawNum.isNotEmpty) {
          final card = await db.findCardByNumberOrName(rawNum);
          if (card != null) {
            matchedCards.add(card);
            if (slot.contains('grade_') && grade >= 0 && grade <= 3) {
              rideSlots[grade] = card;
            }
          } else {
            skippedCardNumbers.add(rawNum);
          }
        }
      }
    }

    // 2. Rebuild Main Deck (list)
    final mainCards = <SavedDeckEntry>[];
    final list = deckJson['list'] as List<dynamic>? ?? [];

    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final rawNum = item['card_number'] as String? ?? '';
        final qty = (item['num'] as int?) ?? 1;

        if (rawNum.isNotEmpty) {
          final card = await db.findCardByNumberOrName(rawNum);
          if (card != null) {
            matchedCards.add(card);
            
            // Avoid adding double entries
            final idx = mainCards.indexWhere((e) => e.card.id == card.id);
            if (idx != -1) {
              mainCards[idx] = SavedDeckEntry(card: card, quantity: mainCards[idx].quantity + qty);
            } else {
              mainCards.add(SavedDeckEntry(card: card, quantity: qty));
            }
          } else {
            skippedCardNumbers.add(rawNum);
          }
        }
      }
    }

    final deck = SavedDeck(
      id: 'decklog_$deckCode',
      name: name.trim().isEmpty ? 'Deck Log $deckCode' : name.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      rideLineSlots: rideSlots,
      mainCards: mainCards,
    );

    return DeckLogImportResult(
      deck: deck,
      matchedCards: matchedCards,
      skippedCardNumbers: skippedCardNumbers,
    );
  }
}

// ── Service Result Models ─────────────────────────────────────────────────

class TextImportResult {
  final SavedDeck deck;
  final List<TextImportMatch> matches;
  final List<String> skippedLines;

  TextImportResult({
    required this.deck,
    required this.matches,
    required this.skippedLines,
  });
}

class TextImportMatch {
  final VgCard card;
  final int quantity;

  TextImportMatch({
    required this.card,
    required this.quantity,
  });
}

class DeckLogImportResult {
  final SavedDeck deck;
  final List<VgCard> matchedCards;
  final List<String> skippedCardNumbers;

  DeckLogImportResult({
    required this.deck,
    required this.matchedCards,
    required this.skippedCardNumbers,
  });
}

