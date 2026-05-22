import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();
  
  // Test POST system/en/api/view/4DWCZ
  await testUrl(client, 'POST', 'https://decklog-en.bushiroad.com/system/en/api/view/4DWCZ');
  // Test GET system/en/api/view/4DWCZ
  await testUrl(client, 'GET', 'https://decklog-en.bushiroad.com/system/en/api/view/4DWCZ');
  // Test POST system/ja/api/view/4DWCZ
  await testUrl(client, 'POST', 'https://decklog-en.bushiroad.com/system/ja/api/view/4DWCZ');
  // Test GET system/ja/api/view/4DWCZ
  await testUrl(client, 'GET', 'https://decklog-en.bushiroad.com/system/ja/api/view/4DWCZ');

  client.close();
}

Future<void> testUrl(HttpClient client, String method, String url) async {
  print('=== Testing $method on $url ===');
  try {
    final uri = Uri.parse(url);
    final request = await client.openUrl(method, uri);
    request.headers.set('accept', 'application/json, text/plain, */*');
    request.headers.set('content-type', 'application/json;charset=UTF-8');
    
    // Send empty payload for POST
    if (method == 'POST') {
      request.write(jsonEncode({}));
    }
    
    final response = await request.close();
    print('Status: ${response.statusCode}');
    final body = await response.transform(utf8.decoder).join();
    print('Response length: ${body.length}');
    if (body.length > 500) {
      print(body.substring(0, 500));
    } else {
      print(body);
    }
  } catch (e) {
    print('Error: $e');
  }
}
