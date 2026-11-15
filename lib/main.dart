import 'package:flutter/material.dart';
import 'app.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database factory according to active platform (Web, Android/iOS, Desktop)
  DatabaseHelper.initializeDatabaseFactory();

  runApp(const MoodoraApp());
}
