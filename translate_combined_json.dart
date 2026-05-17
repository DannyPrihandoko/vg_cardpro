import 'dart:convert';
import 'dart:io';
import 'package:translator/translator.dart';

void main() async {
  final file = File('assets/vanguard_combined.json');
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
    'ぬばたま': 'Nubatama',
    'かげろう': 'Kagero',
    'たちかぜ': 'Tachikaze',
    'むらくも': 'Murakumo',
    'なるかみ': 'Narukami',
    'ロイヤルパラディン': 'Royal Paladin',
    'オラクルシンクタンク': 'Oracle Think Tank',
    'シャドウパラディン': 'Shadow Paladin',
    'ゴールドパラディン': 'Gold Paladin',
    'エンジェルフェザー': 'Angel Feather',
    'ジェネシス': 'Genesis',
    'ダークイレギュラーズ': 'Dark Irregulars',
    'スパイクブラザーズ': 'Spike Brothers',
    'ペイルムーン': 'Pale Moon',
    'ギアクロニクル': 'Gear Chronicle',
    'ノヴァグラップラー': 'Nova Grappler',
    'ディメンジョンポリス': 'Dimension Police',
    'エトランジェ': 'Etranger',
    'リンクジョーカー': 'Link Joker',
    'メガコロニー': 'Megacolony',
    'グレートネイチャー': 'Great Nature',
    'ネオネクタール': 'Neo Nectar',
    'グランブルー': 'Granblue',
    'バミューダ△': 'Bermuda Triangle',
    'アクアフォース': 'Aqua Force',
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
    
    // Check if it actually contains Japanese characters before translating
    // (Hiragana, Katakana, Kanji ranges)
    final RegExp japaneseRegex = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    if (!japaneseRegex.hasMatch(text)) {
      return text;
    }

    String preProcessed = applyDict(text);
    if (!japaneseRegex.hasMatch(preProcessed)) {
      cache[text] = preProcessed;
      return preProcessed;
    }

    await Future.delayed(Duration(milliseconds: 200));
    try {
      final translation = await translator.translate(preProcessed, from: 'ja', to: 'en');
      cache[text] = translation.text;
      return translation.text;
    } catch (e) {
      print('Translation error for: $text \n $e');
      return text;
    }
  }

  int totalCards = 0;
  for (var set in data) {
    final List<dynamic> cards = set['cards'];
    totalCards += cards.length;
  }

  int processedCount = 0;

  for (var set in data) {
    final List<dynamic> cards = set['cards'];
    for (var c in cards) {
      processedCount++;
      
      if (c['clan'] != null) {
        c['clan'] = await translateText(c['clan']);
      }
      if (c['nation'] != null) {
        c['nation'] = await translateText(c['nation']);
      }
      if (c['race'] != null) {
        c['race'] = await translateText(c['race']);
      }
      
      // Translate names
      if (c['name'] != null && c['name']['original'] != null) {
        c['name']['translated'] = await translateText(c['name']['original']);
      }
      // Translate effect text
      if (c['effect_text'] != null && c['effect_text']['original'] != null) {
        c['effect_text']['translated'] = await translateText(c['effect_text']['original']);
      }
      // Translate flavor text
      if (c['flavor_text'] != null && c['flavor_text']['original'] != null) {
        c['flavor_text']['translated'] = await translateText(c['flavor_text']['original']);
      }

      print('Processed $processedCount/$totalCards: ${c['name']['translated']}');
    }
  }

  await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
  print('Done parsing and translating!');
}
