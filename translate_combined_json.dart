import 'dart:convert';
import 'dart:io';
import 'package:translator/translator.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final dbFile = File('assets/vanguard_combined.json');
  final cacheFile = File('assets/translation_cache.json');

  if (!await dbFile.exists()) {
    print('Error: assets/vanguard_combined.json not found!');
    return;
  }

  // Load Database
  print('Loading database...');
  final dbContent = await dbFile.readAsString();
  final List<dynamic> data = jsonDecode(dbContent);

  // Load Translation Cache
  Map<String, String> cache = {};
  if (await cacheFile.exists()) {
    print('Loading translation cache...');
    try {
      final cacheContent = await cacheFile.readAsString();
      final decoded = jsonDecode(cacheContent);
      if (decoded is Map) {
        cache = decoded.map((key, value) => MapEntry(key.toString(), value.toString()));
      }
      print('Loaded ${cache.length} cached translations.');
    } catch (e) {
      print('Warning: Failed to load translation cache ($e). Starting fresh.');
    }
  } else {
    print('No translation cache found. A new one will be created.');
  }

  final translator = GoogleTranslator();

  // Core Japanese keyword replacement dictionary
  final Map<String, String> dict = {
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

  final RegExp japaneseRegex = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');

  // Helper: check if a string contains Japanese characters
  bool hasJapanese(String? text) {
    if (text == null || text.isEmpty) return false;
    return japaneseRegex.hasMatch(text);
  }

  // Pre-process with dictionary
  String applyDict(String text) {
    String res = text;
    dict.forEach((key, value) {
      res = res.replaceAll(key, value);
    });
    return res;
  }

  // Fandom Wiki official English name fetcher
  Future<String> getOfficialEnglishName(String jpName) async {
    try {
      final url = Uri.parse(
          'https://cardfight.fandom.com/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(jpName)}&utf8=&format=json');
      final response = await http.get(url).timeout(Duration(seconds: 8));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['query'] != null &&
            decoded['query']['search'] != null &&
            decoded['query']['search'].isNotEmpty) {
          String title = decoded['query']['search'][0]['title'];
          // Clean suffixes like " (D Series)", " (V Series)", etc.
          title = title.replaceAll(RegExp(r'\s*\([^)]+\)$'), '');
          return title;
        }
      }
    } catch (e) {
      // Fail silently and let translator fallback handle it
    }
    return '';
  }

  int apiCalls = 0;
  int wikiCalls = 0;
  int cacheHits = 0;
  int dirtyCount = 0;

  // Save current database and cache progress
  Future<void> saveProgress() async {
    print('\n[System] Saving progress...');
    try {
      await dbFile.writeAsString(JsonEncoder.withIndent('  ').convert(data));
      await cacheFile.writeAsString(JsonEncoder.withIndent('  ').convert(cache));
      print('[System] Autosave successful. Cache entries: ${cache.length}\n');
      dirtyCount = 0;
    } catch (e) {
      print('[ERROR] Failed to save progress: $e\n');
    }
  }

  // Translate text with caching, smart-checking, and backoff retries
  Future<String> translateText(String text, {bool isName = false}) async {
    if (text.isEmpty || text == '-') return text;

    // 1. Check cache first
    if (cache.containsKey(text)) {
      cacheHits++;
      return cache[text]!;
    }

    // 2. If it doesn't even have Japanese, return as-is
    if (!hasJapanese(text)) {
      cache[text] = text;
      dirtyCount++;
      return text;
    }

    // 3. Special handling for names using Vanguard Wiki API
    if (isName) {
      wikiCalls++;
      String officialName = await getOfficialEnglishName(text);
      if (officialName.isNotEmpty && !hasJapanese(officialName)) {
        cache[text] = officialName;
        dirtyCount++;
        return officialName;
      }
    }

    // 4. Regular Google Translate with keyword pre-processing and retry backoff
    String preProcessed = applyDict(text);
    if (!hasJapanese(preProcessed)) {
      cache[text] = preProcessed;
      dirtyCount++;
      return preProcessed;
    }

    int retryAttempt = 0;
    int backoffSeconds = 2;

    while (true) {
      try {
        apiCalls++;
        await Future.delayed(Duration(milliseconds: 150));
        final translation = await translator.translate(preProcessed, from: 'ja', to: 'en');
        final result = translation.text;

        cache[text] = result;
        dirtyCount++;
        return result;
      } catch (e) {
        retryAttempt++;
        print('\n[Warning] Translation error on attempt $retryAttempt for: "$text" ($e)');
        
        if (retryAttempt >= 5) {
          print('[Error] Max retries reached. Returning pre-processed text temporarily.');
          return preProcessed;
        }

        print('Retrying in $backoffSeconds seconds...');
        await Future.delayed(Duration(seconds: backoffSeconds));
        backoffSeconds *= 2; // Exponential backoff (2s, 4s, 8s, 16s...)
      }
    }
  }

  // Gather stats
  int totalCards = 0;
  for (var set in data) {
    totalCards += (set['cards'] as List).length;
  }

  int processedCount = 0;
  int skippedCards = 0;
  final stopwatch = Stopwatch()..start();

  print('Starting database translation. Total cards: $totalCards\n');

  for (var set in data) {
    final List<dynamic> cards = set['cards'];
    for (var c in cards) {
      processedCount++;

      // Check if this card requires translation on any field
      bool cardNeedsTranslation = false;

      // 1. Clan
      final clanOriginal = c['clan'];
      if (clanOriginal != null && clanOriginal is String && clanOriginal.isNotEmpty) {
        if (hasJapanese(clanOriginal)) {
          cardNeedsTranslation = true;
        }
      }

      // 2. Nation
      final nationOriginal = c['nation'];
      if (nationOriginal != null && nationOriginal is String && nationOriginal.isNotEmpty) {
        if (hasJapanese(nationOriginal)) {
          cardNeedsTranslation = true;
        }
      }

      // 3. Race
      final raceOriginal = c['race'];
      if (raceOriginal != null && raceOriginal is String && raceOriginal.isNotEmpty) {
        if (hasJapanese(raceOriginal)) {
          cardNeedsTranslation = true;
        }
      }

      // 4. Name
      if (c['name'] != null) {
        final translatedName = c['name']['translated'];
        if (translatedName == null || translatedName.isEmpty || hasJapanese(translatedName)) {
          cardNeedsTranslation = true;
        }
      }

      // 5. Effect Text
      if (c['effect_text'] != null) {
        final translatedEffect = c['effect_text']['translated'];
        if (translatedEffect == null || translatedEffect.isEmpty || hasJapanese(translatedEffect)) {
          cardNeedsTranslation = true;
        }
      }

      // 6. Flavor Text
      if (c['flavor_text'] != null) {
        final translatedFlavor = c['flavor_text']['translated'];
        if (translatedFlavor == null || translatedFlavor.isEmpty || hasJapanese(translatedFlavor)) {
          cardNeedsTranslation = true;
        }
      }

      // If everything is already translated, skip processing this card to save time!
      if (!cardNeedsTranslation) {
        skippedCards++;
        continue;
      }

      // Perform actual translation using raw original fields
      if (c['clan'] != null && c['clan'] is String) {
        c['clan'] = await translateText(c['clan']);
      }
      if (c['nation'] != null && c['nation'] is String) {
        c['nation'] = await translateText(c['nation']);
      }
      if (c['race'] != null && c['race'] is String) {
        c['race'] = await translateText(c['race']);
      }

      if (c['name'] != null && c['name']['original'] != null) {
        c['name']['translated'] = await translateText(c['name']['original'], isName: true);
      }

      if (c['effect_text'] != null && c['effect_text']['original'] != null) {
        c['effect_text']['translated'] = await translateText(c['effect_text']['original']);
      }

      if (c['flavor_text'] != null && c['flavor_text']['original'] != null) {
        c['flavor_text']['translated'] = await translateText(c['flavor_text']['original']);
      }

      // Periodic autosave checkpoint
      if (dirtyCount >= 50) {
        await saveProgress();
      }

      // Output Premium Console Progress Tracker
      final percentage = (processedCount / totalCards * 100).toStringAsFixed(1);
      final elapsed = stopwatch.elapsed;
      final speed = processedCount / (elapsed.inMilliseconds / 1000.0);
      final remaining = totalCards - processedCount;
      final etaSeconds = speed > 0 ? (remaining / speed).round() : 0;
      final eta = Duration(seconds: etaSeconds);

      final cardName = c['name']?['translated'] ?? c['name']?['original'] ?? 'Unknown';
      
      stdout.write('\r[Progress: $percentage%] Card $processedCount/$totalCards | '
          'Skips: $skippedCards | '
          'Hits: $cacheHits | '
          'APIs: $apiCalls (Wiki: $wikiCalls) | '
          'ETA: ${eta.inMinutes}m ${eta.inSeconds % 60}s | '
          'Current: $cardName                      ');
    }
  }

  // Final Save
  await saveProgress();
  stopwatch.stop();

  final elapsed = stopwatch.elapsed;
  print('\n------------------------------------------------');
  print('Database Translation Completed Successfully!');
  print('Total Cards: $totalCards');
  print('Skipped (Already Translated): $skippedCards');
  print('Cache Hits: $cacheHits');
  print('Google Translate API Calls: $apiCalls');
  print('Wiki Search API Calls: $wikiCalls');
  print('Total Time Elapsed: ${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s');
  print('------------------------------------------------');
}
