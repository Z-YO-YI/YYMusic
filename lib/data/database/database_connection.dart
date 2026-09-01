import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

typedef SupportDirectoryProvider = Future<Directory> Function();

/// Creates an isolated, ephemeral database for explicit development fixtures
/// and repository tests. Production startup must use [openDefaultDatabase].
AppDatabase openInMemoryDatabase() => AppDatabase(NativeDatabase.memory());

/// Opens the shared Android/Windows database only when explicitly requested.
Future<AppDatabase> openDefaultDatabase({
  SupportDirectoryProvider supportDirectory = getApplicationSupportDirectory,
}) async {
  final supportRoot = await supportDirectory();
  final databaseDirectory = Directory(path.join(supportRoot.path, 'YYMusic'));
  await databaseDirectory.create(recursive: true);
  final databaseFile = File(
    path.join(databaseDirectory.path, 'yymusic.sqlite'),
  );
  return AppDatabase(NativeDatabase.createInBackground(databaseFile));
}
