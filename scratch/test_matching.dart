import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() async {
  // We need to run inside a Flutter context to access getDatabasesPath,
  // but we can just find the database path in local app data directory on Windows.
  // The database is located at: C:\Users\User\AppData\Roaming\com.example\vanguard_db.db
  // Or similar. Let's see if we can open it.
  final dbPath = 'C:\\Users\\User\\AppData\\Roaming\\com.example\\vanguard_db.db';
  print('Trying to open database at: $dbPath');
  
  if (!await File(dbPath).exists()) {
    print('Database file does not exist at default location. Let\'s check where it might be.');
    // Let's search using standard dart directories if needed.
    return;
  }

  // Open database
  final db = await openReadOnlyDatabase(dbPath);
  print('Database opened successfully.');

  final testNumbers = [
    'DZ-SS14/001R',
    'DZ-SS14/002R',
    'DZ-SS14/003',
    'D-PR/851',
    'DZ-SS09/020'
  ];

  for (final rawNum in testNumbers) {
    print('\nMatching: $rawNum');
    // Extract base number
    final baseNum = getBaseCardNumber(rawNum);
    print('  Base Number: $baseNum');

    // Query SQLite
    final rows = await db.query('cards', where: 'id = ? OR id LIKE ?', whereArgs: [baseNum, '$baseNum%']);
    print('  Found ${rows.length} matches:');
    for (final row in rows) {
      print('    - ID: ${row['id']}, Name: ${row['name']}');
    }
  }

  await db.close();
}

String getBaseCardNumber(String raw) {
  final clean = raw.trim().toUpperCase();
  // Regex to match e.g. DZ-BT03/001 or D-PR/851 or BT14-001
  final regex = RegExp(r'^([A-Z0-9-]+/[0-9]+|[A-Z0-9]+-[0-9]+)');
  final match = regex.firstMatch(clean);
  if (match != null) {
    return match.group(1)!;
  }
  return clean;
}
