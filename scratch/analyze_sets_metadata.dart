import 'dart:io';
import 'dart:convert';

void main() async {
  final file = File('assets/vanguard_combined.json');
  if (!await file.exists()) {
    print('File does not exist!');
    return;
  }
  
  final jsonString = await file.readAsString();
  final List<dynamic> jsonList = jsonDecode(jsonString);
  
  for (var setJson in jsonList) {
    final setName = setJson['set_name'] ?? 'Unknown Set';
    final cards = setJson['cards'] as List? ?? [];
    final nations = cards.map((c) => c['nation'] ?? '').where((n) => n.toString().isNotEmpty).toSet().toList();
    final firstCardNames = cards.take(3).map((c) => c['name']?['translated'] ?? c['name']?['original'] ?? '').toList();
    print('Set: $setName | Nations: $nations | Sample: $firstCardNames');
  }
}
