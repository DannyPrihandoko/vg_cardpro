import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/vanguard_database.json');
  final content = await file.readAsString();
  final List<dynamic> data = jsonDecode(content);
  for(var c in data) {
    if (c['unit_type'] == '迷いなく敵を葬る、冷徹の刃。') {
      print(c['name']['original']);
      print(c['unit_type']);
      print(c['trigger']);
    }
  }
}
