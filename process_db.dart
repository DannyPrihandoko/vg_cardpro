import 'dart:convert';
import 'dart:io';
import 'package:translator/translator.dart';

void main() async {
  final file = File('assets/vanguard_database.json');
  final content = await file.readAsString();
  final List<dynamic> data = jsonDecode(content);
  final translator = GoogleTranslator();

  Map<String, String> dict = {
    '【自】': '[AUTO]',
    '【起】': '[ACT]',
    '【永】': '[CONT]',
    '【コスト】': 'COST ',
    '【ソウルブラスト】': 'Soul Blast',
    '【カウンターブラスト】': 'Counter Blast',
    '【エネルギーブラスト】': 'Energy Blast',
    '【エネルギーチャージ】': 'Energy Charge',
    '【ソウルチャージ】': 'Soul Charge',
    '【カウンターチャージ】': 'Counter Charge',
    '【スタンド】': '[Stand]',
    '【レスト】': '[Rest]',
    'ターン1回': '1/Turn',
    'ヴァンガード': 'vanguard',
    'リアガード': 'rear-guard',
    'ドロップ': 'drop zone',
    'ソウル': 'soul',
    'ライドデッキ': 'ride deck',
    'ペルソナライド': 'Persona Ride',
    'シールド': 'Shield',
    'パワー': 'Power',
    '登場した時': 'placed',
  };

  String applyDict(String text) {
    String res = text;
    dict.forEach((key, value) {
      res = res.replaceAll(key, value);
    });
    return res;
  }
  
  Map<String, String> cache = {};
  
  Future<String> translateText(String text) async {
    if (text.isEmpty || text == '-') return text;
    if (cache.containsKey(text)) return cache[text]!;
    
    String preProcessed = applyDict(text);
    await Future.delayed(Duration(milliseconds: 200));
    try {
      final translation = await translator.translate(preProcessed, from: 'ja', to: 'en');
      cache[text] = translation.text;
      return translation.text;
    } catch (e) {
      print('Translation error for: \$text \\n \$e');
      return text;
    }
  }

  final regex = RegExp(r'^(.*?ユニット|Gユニット)\s+(.+?)\s+グレード\s+(.+?)\s+パワー\s+(.+?)\s+クリティカル\s+(.+?)\s+シールド\s+(.+?)\s+(.+?)\s+(.+)$');
  final regex2 = RegExp(r'^(.*?ユニット|Gユニット)\s+(.+?)\s+グレード\s+(.+?)\s+パワー\s+(.+?)\s+クリティカル\s+(.+?)\s+シールド\s+(.+?)\s+(.+)$');

  for(int i = 0; i < data.length; i++) {
    var c = data[i];
    
    String rawUnitType = c['unit_type'] ?? '';
    String rawTrigger = c['trigger'] ?? '';
    
    // Check if scraper swapped flavor text and trigger
    if (rawTrigger.contains('グレード') && !rawUnitType.contains('グレード')) {
      if (c['flavor_text'] != null) {
        c['flavor_text']['original'] = rawUnitType;
      }
      rawUnitType = rawTrigger.replaceFirst('ユニット', 'トリガーユニット'); 
    }

    if (rawUnitType.isNotEmpty) {
      var match = regex.firstMatch(rawUnitType);
      if (match != null) {
        c['unit_type'] = await translateText(match.group(1)!);
        
        // Split group(2) to nation and race
        List<String> restParts = match.group(2)!.split(' ');
        if (restParts.isNotEmpty) {
          if (restParts.length == 1) {
             c['nation'] = await translateText(restParts[0]);
             c['race'] = '';
          } else {
             c['nation'] = await translateText(restParts[0]);
             c['race'] = await translateText(restParts.sublist(1).join(' '));
          }
        }
        
        c['grade'] = match.group(3)!;
        c['power'] = match.group(4)!;
        c['critical'] = match.group(5)!;
        c['shield'] = match.group(6)!;
        c['skill'] = await translateText(match.group(7)!);
        c['trigger'] = await translateText(match.group(8)!);
      } else {
        var match2 = regex2.firstMatch(rawUnitType);
        if (match2 != null) {
          c['unit_type'] = await translateText(match2.group(1)!);
          
          List<String> restParts = match2.group(2)!.split(' ');
          if (restParts.isNotEmpty) {
            if (restParts.length == 1) {
               c['nation'] = await translateText(restParts[0]);
               c['race'] = '';
            } else {
               c['nation'] = await translateText(restParts[0]);
               c['race'] = await translateText(restParts.sublist(1).join(' '));
            }
          }
          
          c['grade'] = match2.group(3)!;
          c['power'] = match2.group(4)!;
          c['critical'] = match2.group(5)!;
          c['shield'] = match2.group(6)!;
          c['skill'] = await translateText(match2.group(7)!);
          c['trigger'] = '-';
        } else {
          c['unit_type'] = await translateText(rawUnitType);
        }
      }
    }

    // Translate name, effect, flavor
    if (c['name'] != null && c['name']['original'] != null) {
      c['name']['translated'] = await translateText(c['name']['original']);
    }
    if (c['effect_text'] != null && c['effect_text']['original'] != null) {
      c['effect_text']['translated'] = await translateText(c['effect_text']['original']);
    }
    if (c['flavor_text'] != null && c['flavor_text']['original'] != null) {
      c['flavor_text']['translated'] = await translateText(c['flavor_text']['original']);
    }
    
    print("Processed ${i+1}/${data.length}: ${c['name']['original']}");
  }

  await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
  print('Done parsing and translating!');
}
