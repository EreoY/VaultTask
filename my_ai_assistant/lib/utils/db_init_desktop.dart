import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initDesktopDb() {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
