import 'dart:convert';
import 'dart:io';

void main() async {
  final combinedFile = File('assets/vanguard_combined.json');
  final databaseFile = File('assets/vanguard_database.json');

  if (!await combinedFile.exists()) {
    print('Error: assets/vanguard_combined.json not found!');
    return;
  }

  print('Reading vanguard_combined.json...');
  final combinedContent = await combinedFile.readAsString();
  final List<dynamic> combinedData = jsonDecode(combinedContent);

  int modifiedCount = 0;

  // Dictionary for correcting card names
  final Map<String, String> nameCorrections = {
    'drag glitter latifa': 'Dragritter, Latifa',
    'drag glitter': 'Dragritter',
    'draglitter': 'Dragritter',
    'Draglitter': 'Dragritter',
    'dragritter': 'Dragritter',
    'Red Treasure Beast Garnet': 'Red Jewel Beast, Garnet',
    'Whirlwind Dragon Voldon': 'Whirlwind Dragon, Voldon',
    'Draglitter Nazrudeen': 'Dragritter, Nazrudeen',
    'enma stealth rogue, mujinlord': 'Enma Stealth Rogue, Mujinlord',
    'Enma Stealth Rogue Mujinlord': 'Enma Stealth Rogue, Mujinlord',
    'shojodoji': 'Shojodoji',
    'blaster blade': 'Blaster Blade',
    'alfred': 'Alfred',
  };

  // Helper to capitalize words properly
  String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    
    // Check if it matches any specific correction first (case-insensitive)
    for (var key in nameCorrections.keys) {
      if (text.toLowerCase() == key.toLowerCase()) {
        return nameCorrections[key]!;
      }
    }

    // Otherwise do a general capitalization
    final words = text.split(' ');
    final capitalized = words.map((word) {
      if (word.isEmpty) return '';
      // If it contains a comma or dash, capitalize parts
      if (word.contains('-')) {
        return word.split('-').map((w) {
          if (w.isEmpty) return '';
          return w[0].toUpperCase() + w.substring(1);
        }).join('-');
      }
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');

    // Post-process name words to ensure standard Vanguard name capitalization
    String res = capitalized;
    nameCorrections.forEach((key, value) {
      res = res.replaceAll(RegExp(key, caseSensitive: false), value);
    });
    return res;
  }

  // Optimize and clean translated text effects
  String cleanEffectText(String text) {
    if (text.isEmpty || text == '-') return text;

    String clean = text;

    // 1. Clean COST syntax
    clean = clean.replaceAll(RegExp(r'\bby\s+COST\s*\[', caseSensitive: false), 'COST [');
    clean = clean.replaceAll(RegExp(r'\bby\s+paying\s*\[', caseSensitive: false), 'COST [');
    clean = clean.replaceAll(RegExp(r'\bCOST\b\s*:\s*\[', caseSensitive: false), 'COST [');

    // 2. Standardize power/shield additions to official syntax "gets Power +X" instead of "+X Power"
    clean = clean.replaceAll(RegExp(r'\+\s*([0-9,]+)\s*[Pp]ower', caseSensitive: false), 'Power +\$1');
    clean = clean.replaceAll(RegExp(r'\+\s*([0-9,]+)\s*[Ss]hield', caseSensitive: false), 'Shield +\$1');
    clean = clean.replaceAll(RegExp(r'\bPower\s*\+\s*([0-9,]+)', caseSensitive: false), 'Power +\$1');
    clean = clean.replaceAll(RegExp(r'\bShield\s*\+\s*([0-9,]+)', caseSensitive: false), 'Shield +\$1');
    
    // Ensure spacing around operators is perfect
    clean = clean.replaceAll(RegExp(r'Power\s*\+\s*([0-9,]+)'), 'Power +\$1');
    clean = clean.replaceAll(RegExp(r'Shield\s*\+\s*([0-9,]+)'), 'Shield +\$1');

    // 3. Official terms capitalization
    clean = clean.replaceAll(RegExp(r'\bvanguard(?!\s*circle)\b', caseSensitive: false), 'vanguard');
    clean = clean.replaceAll(RegExp(r'\brear-guard(?!\s*circle)\b', caseSensitive: false), 'rear-guard');
    clean = clean.replaceAll(RegExp(r'\bguardian(?!\s*circle)\b', caseSensitive: false), 'guardian');
    clean = clean.replaceAll(RegExp(r'\bdrop\s*zone\b', caseSensitive: false), 'drop zone');
    clean = clean.replaceAll(RegExp(r'\bsoul\b', caseSensitive: false), 'soul');
    clean = clean.replaceAll(RegExp(r'\bbind\s*zone\b', caseSensitive: false), 'bind zone');
    clean = clean.replaceAll(RegExp(r'\bdamage\s*zone\b', caseSensitive: false), 'damage zone');
    clean = clean.replaceAll(RegExp(r'\bride\s*deck\b', caseSensitive: false), 'ride deck');

    // Capitalize circles/zones when placed
    clean = clean.replaceAll(RegExp(r'\bvanguard\s*circle\b', caseSensitive: false), 'Vanguard circle');
    clean = clean.replaceAll(RegExp(r'\brear-guard\s*circle\b', caseSensitive: false), 'Rear-guard circle');
    clean = clean.replaceAll(RegExp(r'\bguardian\s*circle\b', caseSensitive: false), 'Guardian circle');

    // 4. Grammar fixes for placements and triggers
    clean = clean.replaceAll(RegExp(r'\bIf this unit is placed on \(R\)', caseSensitive: false), 'When this unit is placed on (R)');
    clean = clean.replaceAll(RegExp(r'\bThis unit is placed on \(R\)', caseSensitive: false), 'When this unit is placed on (R)');
    clean = clean.replaceAll(RegExp(r'\bWhen this unit is placed on \(R\) or placed on \(G\)', caseSensitive: false), 'When this unit is placed on (R) or (G)');
    clean = clean.replaceAll(RegExp(r'\bplaced other than the ability of a unit card', caseSensitive: false), 'placed other than by a unit card\'s ability');
    clean = clean.replaceAll(RegExp(r'\bother than the ability of a unit card', caseSensitive: false), 'other than by a unit card\'s ability');

    // 5. Deck Log specific phrasing fixes
    clean = clean.replaceAll(RegExp(r'\bplaces a total of\b', caseSensitive: false), 'put a total of');
    clean = clean.replaceAll(RegExp(r'\bthat were made into a ride deck\b', caseSensitive: false), 'that were in your ride deck');
    
    // 6. Time/duration standardizations
    clean = clean.replaceAll(RegExp(r'\bfor the duration of the turn\b', caseSensitive: false), 'until end of turn');
    clean = clean.replaceAll(RegExp(r'\bfor the turn\b', caseSensitive: false), 'until end of turn');
    clean = clean.replaceAll(RegExp(r'\bduring that battle\b', caseSensitive: false), 'until end of that battle');

    // 7. General cleanups
    clean = clean.replaceAll(RegExp(r'\b1/Turn\b', caseSensitive: false), '[Once per turn]');
    clean = clean.replaceAll(RegExp(r'\bOnce per turn\b', caseSensitive: false), '[Once per turn]');
    clean = clean.replaceAll(RegExp(r'\bbanish this card\b', caseSensitive: false), 'remove this card from play');
    clean = clean.replaceAll(RegExp(r'\bgrade of your vanguard is lower than or equal to\b', caseSensitive: false), 'your vanguard\'s grade is less than or equal to');
    clean = clean.replaceAll(RegExp(r"\byour vanguard's grade is lower than or equal to\b", caseSensitive: false), "your vanguard's grade is less than or equal to");
    clean = clean.replaceAll(RegExp(r'\blook at 5 cards from the top of your deck\b', caseSensitive: false), 'look at the top five cards of your deck');
    clean = clean.replaceAll(RegExp(r'\bchoose up to 1 card\b', caseSensitive: false), 'choose up to one card');
    clean = clean.replaceAll(RegExp(r'\bShuffle the deck\b', caseSensitive: false), 'Shuffle your deck');

    return clean;
  }

  // Process vanguard_combined.json
  for (var set in combinedData) {
    if (set['cards'] != null) {
      final List<dynamic> cards = set['cards'];
      for (var c in cards) {
        // Correct name translation
        if (c['name'] != null && c['name']['translated'] != null) {
          final original = c['name']['translated'] as String;
          final updated = capitalizeWords(original);
          if (original != updated) {
            c['name']['translated'] = updated;
            modifiedCount++;
          }
        }

        // Correct effect_text translation
        if (c['effect_text'] != null && c['effect_text']['translated'] != null) {
          final original = c['effect_text']['translated'] as String;
          final updated = cleanEffectText(original);
          if (original != updated) {
            c['effect_text']['translated'] = updated;
            modifiedCount++;
          }
        }

        // Correct flavor_text translation
        if (c['flavor_text'] != null && c['flavor_text']['translated'] != null) {
          final original = c['flavor_text']['translated'] as String;
          final updated = original.replaceAll(RegExp(r'\bnubata\b', caseSensitive: false), 'Nubatama');
          if (original != updated) {
            c['flavor_text']['translated'] = updated;
            modifiedCount++;
          }
        }
      }
    }
  }

  print('Writing back to assets/vanguard_combined.json...');
  await combinedFile.writeAsString(JsonEncoder.withIndent('  ').convert(combinedData));
  print('Successfully processed vanguard_combined.json. Modified fields: $modifiedCount');

  // Process vanguard_database.json if it exists
  if (await databaseFile.exists()) {
    print('Reading vanguard_database.json...');
    final databaseContent = await databaseFile.readAsString();
    final List<dynamic> databaseData = jsonDecode(databaseContent);
    int dbModifiedCount = 0;

    for (var c in databaseData) {
      if (c['name'] != null && c['name']['translated'] != null) {
        final original = c['name']['translated'] as String;
        final updated = capitalizeWords(original);
        if (original != updated) {
          c['name']['translated'] = updated;
          dbModifiedCount++;
        }
      }

      if (c['effect_text'] != null && c['effect_text']['translated'] != null) {
        final original = c['effect_text']['translated'] as String;
        final updated = cleanEffectText(original);
        if (original != updated) {
          c['effect_text']['translated'] = updated;
          dbModifiedCount++;
        }
      }

      if (c['flavor_text'] != null && c['flavor_text']['translated'] != null) {
        final original = c['flavor_text']['translated'] as String;
        final updated = original.replaceAll(RegExp(r'\bnubata\b', caseSensitive: false), 'Nubatama');
        if (original != updated) {
          c['flavor_text']['translated'] = updated;
          dbModifiedCount++;
        }
      }
    }

    print('Writing back to assets/vanguard_database.json...');
    await databaseFile.writeAsString(JsonEncoder.withIndent('  ').convert(databaseData));
    print('Successfully processed vanguard_database.json. Modified fields: $dbModifiedCount');
  }

  print('All translations optimized successfully! Please trigger background sync or hot restart.');
}
