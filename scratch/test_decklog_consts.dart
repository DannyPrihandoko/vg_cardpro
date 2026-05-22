import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();
  
  final urls = [
    'https://decklog-en.bushiroad.com/ja/conf/const.js',
    'https://decklog-en.bushiroad.com/conf/const.js',
    'https://decklog.bushiroad.com/ja/conf/const.js',
  ];

  for (final url in urls) {
    print('=== Testing GET $url ===');
    try {
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);
      final response = await request.close();
      print('Status: ${response.statusCode}');
      
      final body = await response.transform(utf8.decoder).join();
      print('Length: ${body.length}');
      if (body.isNotEmpty) {
        print(body);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  client.close();
}
