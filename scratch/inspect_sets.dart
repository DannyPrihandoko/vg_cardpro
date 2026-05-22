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
  
  print('Total sets: ${jsonList.length}');
  for (var setJson in jsonList) {
    final setName = setJson['set_name'] ?? 'Unknown Set';
    final cards = setJson['cards'] as List? ?? [];
    print('- $setName (${cards.length} cards)');
  }
}
