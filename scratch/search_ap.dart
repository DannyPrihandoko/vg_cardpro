import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();
  
  final jsUrls = [
    'https://decklog-en.bushiroad.com/ja/static/js/app.cbba66c9.js',
    'https://decklog-en.bushiroad.com/ja/static/js/chunk-vendors.02b680f5.js',
    'https://decklog-en.bushiroad.com/ja/static/js/chunk-2d0af6e9.8a95b603.js',
  ];

  for (final url in jsUrls) {
    print('=== Searching in $url ===');
    try {
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      
      int index = 0;
      while (true) {
        index = body.indexOf('__ap', index);
        if (index == -1) break;
        final start = (index - 100).clamp(0, body.length);
        final end = (index + 100).clamp(0, body.length);
        print('Match at $index:');
        print(body.substring(start, end));
        index += 4;
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  client.close();
}
