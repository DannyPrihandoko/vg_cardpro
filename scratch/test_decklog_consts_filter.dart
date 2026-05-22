import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();
  
  try {
    final uri = Uri.parse('https://decklog-en.bushiroad.com/ja/conf/const.js');
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    final lines = body.split('\n');
    print('Total lines: ${lines.length}');
    for (final line in lines) {
      if (line.contains('__const') || line.contains('api') || line.contains('url') || line.contains('http') || line.contains('system')) {
        print(line);
      }
    }
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
