import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();
  
  try {
    final uri = Uri.parse('https://decklog-en.bushiroad.com/ja/static/js/chunk-2d0af6e9.8a95b603.js');
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    final searchStr = '/system/app/api/view/';
    final idx = body.indexOf(searchStr);
    if (idx != -1) {
      print('Found index: $idx');
      final start = (idx - 300).clamp(0, body.length);
      final end = (idx + 300).clamp(0, body.length);
      print(body.substring(start, end));
    } else {
      print('Not found: $searchStr');
    }
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
