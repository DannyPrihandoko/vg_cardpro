import 'dart:convert';
import 'dart:io';
import 'package:translator/translator.dart';

void main() async {
  final translator = GoogleTranslator();
  
  String original = "【自】【(V)】【ターン1回】：このユニットがアタックした時、【コスト】[【カウンターブラスト】(1)]することで、１枚引く。相手のヴァンガードがグレード３以上なら、「次元ロボ」を含むそれぞれ別名のあなたのユニットを望む枚数選び、そのターン中、パワー＋5000。【自】【(V)】【ターン1回】：このユニットがアタックしたバトル終了時、【コスト】[手札から１枚ソウルに置く]ことで、このユニットを【スタンド】させ、そのターン中、あなたのヴァンガードすべてのドライブ－２。あなたのバインドゾーンに「次元ロボ ゴーユーシャ」がなくて、このターンにあなたがペルソナライドしているなら、さらに【コスト】[ソウルから「次元ロボ ゴーユーシャ」を１枚バインドする]ことで、そのターン中、このユニットのドライブ＋１。";

  // Test 1: Direct translation without dictionary pre-processing
  print('--- Test 1: Direct Translation ---');
  final res1 = await translator.translate(original, from: 'ja', to: 'en');
  print('Result 1: ${res1.text}\n');

  // Test 2: Pre-processed with dict
  print('--- Test 2: Pre-processed Translation ---');
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
  
  String preProcessed = original;
  dict.forEach((key, value) {
    preProcessed = preProcessed.replaceAll(key, value);
  });
  
  final res2 = await translator.translate(preProcessed, from: 'ja', to: 'en');
  print('Result 2: ${res2.text}\n');
}
