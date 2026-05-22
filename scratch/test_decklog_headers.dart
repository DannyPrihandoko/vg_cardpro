import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();
  
  final url = 'https://decklog-en.bushiroad.com/system/app-ja/api/view/4DWCZ';
  print('=== Testing with headers on $url ===');
  try {
    final uri = Uri.parse(url);
    final request = await client.postUrl(uri);
    request.headers.set('accept', 'application/json, text/plain, */*');
    request.headers.set('content-type', 'application/json;charset=UTF-8');
    request.headers.set('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Chrome/120.0.0.0 Safari/537.36');
    request.headers.set('origin', 'https://decklog-en.bushiroad.com');
    request.headers.set('referer', 'https://decklog-en.bushiroad.com/ja/view/4DWCZ');
    request.headers.set('accept-language', 'ja,en-US;q=0.9,en;q=0.8');
    
    request.write(jsonEncode({}));
    final response = await request.close();
    print('Status: ${response.statusCode}');
    
    final body = await response.transform(utf8.decoder).join();
    print('Length: ${body.length}');
    print(body);
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
