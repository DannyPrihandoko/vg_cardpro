void main() {
  var list = [
    'ノーマルユニット ドラゴンエンパイア ドラゴロイド グレード 2 パワー 10000 クリティカル 1 シールド 5000 インターセプト -',
    'ノーマルユニット ドラゴンエンパイア ブラントゲート ワービースト/バトロイド グレード 2 パワー 10000 クリティカル 1 シールド 5000 インターセプト -',
    'トリガーユニット ズー バイオロイド グレード 0 パワー 5000 クリティカル 1 シールド 15000 ブースト クリティカルトリガー＋10000',
    'ノーマルユニット ダークステイツ ギアドラゴン ギアクロニクル グレード 3 パワー 13000 クリティカル 1 シールド - ツインドライブ、ペルソナライド -'
  ];
  
  final regex = RegExp(r'^(.*?ユニット|Gユニット)\s+(.+?)\s+グレード\s+(.+?)\s+パワー\s+(.+?)\s+クリティカル\s+(.+?)\s+シールド\s+(.+?)\s+(.+?)\s+(.+)$');
  // wait, what about the nation and clan/race?
  // They are in group 2.
  // How to split group 2?
  // the last word in group 2 is the race? or sometimes race + clan.
  for(var s in list) {
    var match = regex.firstMatch(s);
    if (match != null) {
      print('---');
      print('UnitType: \${match.group(1)}');
      print('Rest: \${match.group(2)}');
      print('Grade: \${match.group(3)}');
      print('Power: \${match.group(4)}');
      print('Critical: \${match.group(5)}');
      print('Shield: \${match.group(6)}');
      print('Skill: \${match.group(7)}');
      print('Trigger: \${match.group(8)}');
    }
  }
}
