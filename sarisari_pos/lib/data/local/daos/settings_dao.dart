import 'package:sqflite/sqflite.dart';
import '../db_helper.dart';

class SettingsDao {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<String?> get(String key) async {
    final db = await _db;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    final db = await _db;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final value = await get(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  Future<void> setBool(String key, bool value) => set(key, value.toString());
}
