import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class LocalStore {
  static const _fileName = 'schedules.json';
  static const _manualRoutesFileName = 'manual_routes.json';

  static Future<File> _schedulesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<File> _manualRoutesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_manualRoutesFileName');
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

  // -------- Manual routes (saved locally, not in assets) --------

  /// Read manual route overrides from local storage.
  /// Shape: { "BFO->MISSO": [ {"floor":1, "points":[{"fx":..,"fy":..}, ...]}, ... ] }
  static Future<Map<String, dynamic>> readManualRoutes() async {
    final f = await _manualRoutesFile();
    if (!await f.exists()) {
      await f.writeAsString("{}", flush: true);
    }
    final txt = await f.readAsString();
    final raw = jsonDecode(txt);
    if (raw is Map<String, dynamic>) return raw;
    return <String, dynamic>{};
  }

  static Future<void> writeManualRoutes(Map<String, dynamic> data) async {
    final f = await _manualRoutesFile();
    final txt = const JsonEncoder.withIndent('  ').convert(data);
    await f.writeAsString(txt, flush: true);
  }
}
