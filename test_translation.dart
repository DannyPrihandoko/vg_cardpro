import 'package:translator/translator.dart';

void main() async {
  final translator = GoogleTranslator();
  String text = "【自】：このユニットが、(R)に登場した時か(G)に置かれた時、【コスト】[ソウルかドロップから、ライドデッキにしたカードを合計２枚ライドデッキに表で置く]ことで、このユニットのいるサークルにより以下を１つ行う。・(R)‐１枚引く。・(G)‐そのバトル中、このユニットのシールド＋15000。";

  // Pre-process keywords to protect them from bad translation
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

  String preProcessed = text;
  dict.forEach((key, value) {
    preProcessed = preProcessed.replaceAll(key, value);
  });

  print('Pre-processed: $preProcessed');

  final translation = await translator.translate(preProcessed, from: 'ja', to: 'en');
  
  String postProcessed = translation.text;
  
  print('Translated: $postProcessed');
}
