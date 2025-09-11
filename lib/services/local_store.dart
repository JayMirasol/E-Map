import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class LocalStore {
  static const _fileName = 'schedules.json';

  static Future<File> _schedulesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Ensure the file exists; if not, copy from assets.
  static Future<void> ensureSeeded() async {
    final f = await _schedulesFile();
    if (await f.exists()) return;
    final seed = await rootBundle.loadString('assets/data/schedules.json');
    await f.writeAsString(seed, flush: true);
  }

  static Future<List<Map<String, dynamic>>> readSchedules() async {
    await ensureSeeded();
    final f = await _schedulesFile();
    final txt = await f.readAsString();
    final raw = (jsonDecode(txt) as List).cast<Map<String, dynamic>>();
    return raw;
  }

  static Future<void> writeSchedules(List<Map<String, dynamic>> data) async {
    final f = await _schedulesFile();
    final txt = const JsonEncoder.withIndent('  ').convert(data);
    await f.writeAsString(txt, flush: true);
  }
}
