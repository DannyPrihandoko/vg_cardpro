import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/vanguard_combined.json');
  final content = await file.readAsString();
  final List<dynamic> data = jsonDecode(content);

  final RegExp japaneseRegex = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');

  int printed = 0;
  for (var set in data) {
    for (var c in set['cards']) {
      final translatedEffect = c['effect_text']?['translated'] ?? '';
      if (japaneseRegex.hasMatch(translatedEffect) && printed < 5) {
        print('Card: ${c['card_number']} - ${c['name']?['translated']}');
        print('Original Effect: ${c['effect_text']?['original']}');
        print('Translated Effect: $translatedEffect');
        print('-----------------------------------------');
        printed++;
      }
    }
  }
}
