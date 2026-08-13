import 'package:flutter/material.dart';
import 'app.dart';
import 'data/local/db_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Warm up the local database on startup so the first screen doesn't
  // stall waiting on the initial CREATE TABLE batch.
  await DBHelper.instance.database;

  runApp(const SariSariPosApp());
}
