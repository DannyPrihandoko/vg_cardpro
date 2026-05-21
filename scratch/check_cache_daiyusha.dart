import 'dart:convert';
import 'dart:io';

void main() async {
  final cacheFile = File('assets/translation_cache.json');
  final content = await cacheFile.readAsString();
  final Map<String, dynamic> cache = jsonDecode(content);

  String key = "【自】【(V)】【ターン1回】：このユニットがアタックした時、【コスト】[【カウンターブラスト】(1)]することで、１枚引く。相手のヴァンガードがグレード３以上なら、「次元ロボ」を含むそれぞれ別名のあなたのユニットを望む枚数選び、そのターン中、パワー＋5000。【自】【(V)】【ターン1回】：このユニットがアタックしたバトル終了時、【コスト】[手札から１枚ソウルに置く]ことで、このユニットを【スタンド】させ、そのターン中、あなたのヴァンガードすべてのドライブ－２。あなたのバインドゾーンに「次元ロボ ゴーユーシャ」がなくて、このターンにあなたがペルソナライドしているなら、さらに【コスト】[ソウルから「次元ロボ ゴーユーシャ」を１枚バインドする]ことで、そのターン中、このユニットのドライブ＋１。";
  
  if (cache.containsKey(key)) {
    print('Found cache entry:');
    print(cache[key]);
  } else {
    print('No cache entry found for this key.');
  }
}
