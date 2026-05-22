import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();
  
  final urls = [
    'https://decklog-en.bushiroad.com/system/app/api/view/4DWCZ',
    'https://decklog.bushiroad.com/system/app/api/view/4DWCZ',
  ];

  for (final url in urls) {
    print('=== Testing POST $url ===');
    try {
      final uri = Uri.parse(url);
      final request = await client.postUrl(uri);
      request.headers.set('accept', 'application/json, text/plain, */*');
      request.headers.set('content-type', 'application/json;charset=UTF-8');
      
      request.write(jsonEncode({}));
      final response = await request.close();
      print('Status: ${response.statusCode}');
      
      final body = await response.transform(utf8.decoder).join();
      print('Length: ${body.length}');
      if (body.isNotEmpty) {
        if (body.length > 2000) {
          print(body.substring(0, 2000));
        } else {
          print(body);
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  client.close();
}
