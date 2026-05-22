import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();
  
  final url = 'https://decklog-en.bushiroad.com/system/app-ja/api/view/4DWCZ';
  try {
    final uri = Uri.parse(url);
    final request = await client.postUrl(uri);
    request.headers.set('accept', 'application/json, text/plain, */*');
    request.headers.set('content-type', 'application/json;charset=UTF-8');
    request.headers.set('user-agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    request.headers.set('origin', 'https://decklog-en.bushiroad.com');
    request.headers.set('referer', 'https://decklog-en.bushiroad.com/ja/view/4DWCZ');
    
    request.write(jsonEncode({}));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    final Map<String, dynamic> data = jsonDecode(body);
    print('Root level keys:');
    data.forEach((key, value) {
      if (value is List) {
        print('  $key: List of length ${value.length}');
      } else if (value is Map) {
        print('  $key: Map with ${value.keys.length} keys');
      } else {
        print('  $key: $value');
      }
    });

    if (data['p_list'] is List) {
      print('\nRide Line Cards (p_list):');
      for (final card in data['p_list']) {
        print('  Number: ${card['card_number']}, Name: ${card['name']}, Grade: ${card['grade']}, Slot: ${card['slot']}');
      }
    }
  } catch (e) {
    print('Error: $e');
  }

  client.close();
}
