import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/vanguard_combined.json');
  final content = await file.readAsString();
  final List<dynamic> data = jsonDecode(content);

  final RegExp japaneseRegex = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');

  for (var set in data) {
    for (var c in set['cards']) {
      if (c['card_number'] == 'DZ-BT03/002') {
        final translated = c['effect_text']?['translated'] ?? '';
        print('Translated text: $translated');
        for (int i = 0; i < translated.length; i++) {
          final char = translated[i];
          if (japaneseRegex.hasMatch(char)) {
            print('Matched char: "$char" at index $i (Code: ${char.codeUnitAt(0)})');
          }
        }
      }
    }
  }
}
