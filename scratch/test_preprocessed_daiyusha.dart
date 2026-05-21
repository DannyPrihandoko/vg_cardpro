import 'dart:convert';
import 'dart:io';
import 'package:translator/translator.dart';

void main() async {
  final translator = GoogleTranslator();
  
  String original = "【自】【(V)】【ターン1回】：このユニットがアタックした時、【コスト】[【カウンターブラスト】(1)]することで、１枚引く。相手のヴァンガードがグレード３以上なら、「次元ロボ」を含むそれぞれ別名のあなたのユニットを望む枚数選び、そのターン中、パワー＋5000。【自】【(V)】【ターン1回】：このユニットがアタックしたバトル終了時、【コスト】[手札から１枚ソウルに置く]ことで、このユニットを【スタンド】させ、そのターン中、あなたのヴァンガードすべてのドライブ－２。あなたのバインドゾーンに「次元ロボ ゴーユーシャ」がなくて、このターンにあなたがペルソナライドしているなら、さらに【コスト】[ソウルから「次元ロボ ゴーユーシャ」を１枚バインドする]ことで、そのターン中、このユニットのドライブ＋１。";

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

  String preProcessed = original;
  dict.forEach((key, value) {
    preProcessed = preProcessed.replaceAll(key, value);
  });

  print('Preprocessed text: $preProcessed');
  
  final res = await translator.translate(preProcessed, from: 'ja', to: 'en');
  print('Result: ${res.text}');
}
