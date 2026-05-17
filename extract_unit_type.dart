import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/vanguard_database.json');
  final content = await file.readAsString();
  final List<dynamic> data = jsonDecode(content);
  
  for (int i = 0; i < data.length; i++) {
    final card = data[i];
    final String unitType = card['unit_type'] ?? '';
    final String trigger = card['trigger'] ?? '';
    if (unitType.isNotEmpty) {
      print('unit_type: \$unitType');
    } else if (trigger.isNotEmpty) {
      // In the JSON, some trigger units have their info in the "trigger" field instead!
      print('trigger_as_unit_type: \$trigger');
    }
  }
}
