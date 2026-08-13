import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../data/local/db_helper.dart';

const _uuid = Uuid();
const _settingsKey = 'device_id';

/// Provides a stable identifier for this install, used to bind a license
/// key to one device (see LicenseApi.activate / check-status).
///
/// This is intentionally NOT a hardware ID (IMEI, etc.) — those require
/// extra permissions and vary by Android version. A generated UUID stored
/// in the local `settings` table is stable for the app's lifetime and
/// resets naturally on reinstall, which matches the "one license per
/// install" model described in the licensing flow.
class DeviceIdService {
  Future<Database> get _db async => DBHelper.instance.database;

  Future<String> getOrCreate() async {
    final db = await _db;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [_settingsKey], limit: 1);
    if (rows.isNotEmpty) {
      return rows.first['value'] as String;
    }
    final newId = _uuid.v4();
    await db.insert(
      'settings',
      {'key': _settingsKey, 'value': newId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return newId;
  }
}
