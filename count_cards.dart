import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('assets/vanguard_database.json');
  final content = await file.readAsString();
  final List<dynamic> data = jsonDecode(content);
  print(data.length);
}
