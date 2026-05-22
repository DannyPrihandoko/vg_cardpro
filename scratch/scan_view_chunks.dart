import 'dart:io';
import 'dart:convert';

void main() async {
  final chunks = [
    'chunk-40716f74.4037fbdf.js',
    'chunk-c6f7d5e0.efeb1334.js'
  ];

  final client = HttpClient();

  for (final chunk in chunks) {
    final url = 'https://decklog-en.bushiroad.com/static/js/$chunk';
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        print('=== Scanning $chunk ===');
        
        // Find $http calls
        final httpRegex = RegExp(r"\$http\.[a-zA-Z]+\([^\)]+\)");
        final httpMatches = httpRegex.allMatches(content);
        print('Found ${httpMatches.length} HTTP calls:');
        for (final m in httpMatches) {
          print('  HTTP Call: ${m.group(0)}');
        }

        // Find system/ ja/ en/ API references
        final systemRegex = RegExp(r"/system/[^\s]+");
        final systemMatches = systemRegex.allMatches(content);
        print('Found ${systemMatches.length} system references:');
        for (final m in systemMatches) {
          print('  System Ref: ${m.group(0)}');
        }

        // Print context of any "view" string
        int index = 0;
        while (true) {
          index = content.indexOf('/api/', index);
          if (index == -1) break;
          final start = (index - 60).clamp(0, content.length);
          final end = (index + 60).clamp(0, content.length);
          print('  /api/ match context: ... ${content.substring(start, end).replaceAll('\n', ' ')} ...');
          index += 5;
        }
      }
    } catch (e) {
      print('Error on $chunk: $e');
    }
  }

  client.close();
}
