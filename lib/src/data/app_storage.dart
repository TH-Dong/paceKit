import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<Directory> getAppDocumentsDirectory() async {
  return getApplicationDocumentsDirectory();
}

Future<File> getAppDatabaseFile() async {
  final directory = await getAppDocumentsDirectory();
  return File(p.join(directory.path, 'pacekit.sqlite'));
}

Future<Directory> getAvatarStorageDirectory() async {
  final directory = await getAppDocumentsDirectory();
  return Directory(p.join(directory.path, 'avatars'));
}

Future<File> getAppPreferencesFile() async {
  final directory = await getAppDocumentsDirectory();
  return File(p.join(directory.path, 'pacekit_prefs.json'));
}
