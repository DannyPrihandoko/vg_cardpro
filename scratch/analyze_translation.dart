import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/vanguard_combined.json');
  final content = await file.readAsString();
  final List<dynamic> data = jsonDecode(content);

  final RegExp japaneseRegex = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');

  bool hasActualJapanese(String text) {
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code == 12539) continue; // Skip '・' (Code 12539 / \u30FB)
      if (japaneseRegex.hasMatch(text[i])) return true;
    }
    return false;
  }

  int totalCards = 0;
  int nameJp = 0;
  int effectJp = 0;
  int flavorJp = 0;
  int clanJp = 0;
  int nationJp = 0;
  int raceJp = 0;

  int nameMissing = 0;
  int effectMissing = 0;
  int flavorMissing = 0;

  int originalNoEffect = 0;
  int originalNoFlavor = 0;

  for (var set in data) {
    final List<dynamic> cards = set['cards'];
    totalCards += cards.length;
    for (var c in cards) {
      // Name
      if (c['name'] == null) {
        nameMissing++;
      } else {
        final original = c['name']['original'] ?? '';
        final translated = c['name']['translated'] ?? '';
        if (translated.isEmpty && original.isNotEmpty) {
          nameMissing++;
        } else if (hasActualJapanese(translated)) {
          nameJp++;
        }
      }

      // Effect
      if (c['effect_text'] == null) {
        originalNoEffect++;
      } else {
        final original = c['effect_text']['original'] ?? '';
        final translated = c['effect_text']['translated'] ?? '';
        if (original.isEmpty || original == '-') {
          originalNoEffect++;
        } else if (translated.isEmpty) {
          effectMissing++;
        } else if (hasActualJapanese(translated)) {
          effectJp++;
        }
      }

      // Flavor
      if (c['flavor_text'] == null) {
        originalNoFlavor++;
      } else {
        final original = c['flavor_text']['original'] ?? '';
        final translated = c['flavor_text']['translated'] ?? '';
        if (original.isEmpty || original == '-') {
          originalNoFlavor++;
        } else if (translated.isEmpty) {
          flavorMissing++;
        } else if (hasActualJapanese(translated)) {
          flavorJp++;
        }
      }

      // Clan
      if (c['clan'] != null && hasActualJapanese(c['clan'].toString())) {
        clanJp++;
      }
      // Nation
      if (c['nation'] != null && hasActualJapanese(c['nation'].toString())) {
        nationJp++;
      }
      // Race
      if (c['race'] != null && hasActualJapanese(c['race'].toString())) {
        raceJp++;
      }
    }
  }

  print('Total Cards: $totalCards');
  print('Name: Missing=$nameMissing, Has Japanese=$nameJp');
  print('Effect: Missing=$effectMissing, Has Japanese=$effectJp, No Original Effect=$originalNoEffect');
  print('Flavor: Missing=$flavorMissing, Has Japanese=$flavorJp, No Original Flavor=$originalNoFlavor');
  print('Metadata JP check: Clan JP=$clanJp, Nation JP=$nationJp, Race JP=$raceJp');
}
