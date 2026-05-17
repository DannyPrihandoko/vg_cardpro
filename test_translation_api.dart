import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  String jpName = "閻魔忍鬼 ムジンロード";
  
  // Try searching on Vanguard Wiki
  var url = Uri.parse('https://cardfight.fandom.com/api.php?action=query&list=search&srsearch=$jpName&utf8=&format=json');
  var response = await http.get(url);
  
  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    if (data['query']['search'].isNotEmpty) {
      print("Found: ${data['query']['search'][0]['title']}");
    } else {
      print("Not found for $jpName");
    }
  } else {
    print("Error ${response.statusCode}");
  }
}
