import 'dart:io';
import 'dart:convert';

void main() async {
  final chunks = [
    'chunk-0bf4a737.46a09ca6.js',
    'chunk-16138786.14d7957a.js',
    'chunk-21af2ae0.d02df35e.js',
    'chunk-2d0af6e9.c37489e7.js',
    'chunk-396ab355.707434da.js',
    'chunk-40716f74.4037fbdf.js',
    'chunk-6c6953b1.39f71250.js',
    'chunk-6d16e70c.6e4088ba.js',
    'chunk-7a12ecac.290e0ca1.js',
    'chunk-c6f49124.c975ae08.js',
    'chunk-c6f498c0.46509fa6.js',
    'chunk-c6f59cbe.f7f47d1a.js',
    'chunk-c6f6239a.85161cfb.js',
    'chunk-c6f7d5e0.efeb1334.js',
    'chunk-f63092f4.d903aa49.js',
    'chunk-f7108f1e.7cff31ce.js',
    'chunk-f736305c.6c14b88e.js',
    'chunk-f736865c.bf01e85d.js',
    'chunk-f737df00.48a167d4.js',
    'chunk-f73b2b24.909f9e71.js',
    'app.0be006d4.js'
  ];

  final client = HttpClient();

  for (final chunk in chunks) {
    final url = 'https://decklog-en.bushiroad.com/static/js/$chunk';
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        
        final httpRegex = RegExp(r"\$http\.[a-zA-Z]+\([^\)]+\)");
        final matches = httpRegex.allMatches(content);
        if (matches.isNotEmpty) {
          print('=== $chunk ===');
          for (final m in matches) {
            final matchStr = m.group(0)!;
            // Filter out sort/session/version which we already know
            if (!matchStr.contains('sort') && !matchStr.contains('session') && !matchStr.contains('version')) {
              print('  HTTP Call: $matchStr');
            }
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  client.close();
}
