import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/vanguard_combined.json');
  final content = await file.readAsString();
  final List<dynamic> data = jsonDecode(content);
  print('Number of sets: ${data.length}');
  int totalCards = 0;
  for (var set in data) {
    final List<dynamic> cards = set['cards'];
    totalCards += cards.length;
  }
  print('Total cards: $totalCards');
}
