import 'dart:convert';
import 'dart:io';

void main() async {
  final cacheFile = File('assets/translation_cache.json');
  final dbFile = File('assets/vanguard_combined.json');

  final RegExp japaneseRegex = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');

  bool hasActualJapanese(String text) {
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code == 12539) continue; // Skip '・' (Code 12539 / \u30FB)
      if (japaneseRegex.hasMatch(text[i])) return true;
    }
    return false;
  }

  // 1. Clean Translation Cache
  if (await cacheFile.exists()) {
    final cacheContent = await cacheFile.readAsString();
    final Map<String, dynamic> cache = jsonDecode(cacheContent);
    final initialCount = cache.length;

    cache.removeWhere((key, value) {
      return hasActualJapanese(value.toString());
    });

    final cleanedCount = cache.length;
    await cacheFile.writeAsString(JsonEncoder.withIndent('  ').convert(cache));
    print('Cleaned translation cache: Removed ${initialCount - cleanedCount} bad entries. Remaining: $cleanedCount');
  }

  // 2. Clean Database Translated Fields
  if (await dbFile.exists()) {
    final dbContent = await dbFile.readAsString();
    final List<dynamic> data = jsonDecode(dbContent);
    int clearedFields = 0;

    for (var set in data) {
      for (var c in set['cards']) {
        // Name
        if (c['name'] != null && c['name']['translated'] != null) {
          if (hasActualJapanese(c['name']['translated'])) {
            c['name']['translated'] = '';
            clearedFields++;
          }
        }
        // Effect
        if (c['effect_text'] != null && c['effect_text']['translated'] != null) {
          if (hasActualJapanese(c['effect_text']['translated'])) {
            c['effect_text']['translated'] = '';
            clearedFields++;
          }
        }
        // Flavor
        if (c['flavor_text'] != null && c['flavor_text']['translated'] != null) {
          if (hasActualJapanese(c['flavor_text']['translated'])) {
            c['flavor_text']['translated'] = '';
            clearedFields++;
          }
        }
        // Clan, Nation, Race
        if (c['clan'] != null && hasActualJapanese(c['clan'])) {
          c['clan'] = '';
          clearedFields++;
        }
        if (c['nation'] != null && hasActualJapanese(c['nation'])) {
          c['nation'] = '';
          clearedFields++;
        }
        if (c['race'] != null && hasActualJapanese(c['race'])) {
          c['race'] = '';
          clearedFields++;
        }
      }
    }

    await dbFile.writeAsString(JsonEncoder.withIndent('  ').convert(data));
    print('Cleaned database: Cleared $clearedFields partially-translated fields containing Japanese.');
  }
}
