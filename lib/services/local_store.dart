import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalStore {
  static const _fileName = 'schedules.json';
  static const _manualRoutesFileName = 'manual_routes.json';
  static const _manualRoutesAssetPath = 'assets/data/manual_routes.json';

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

  // -------- Manual routes (hybrid: read from assets + local storage) --------

  /// Read manual route overrides from both assets (bundled) and local storage (newly created).
  /// Local routes override/supplement bundled routes.
  /// Shape: { "1:BFO->MISSO": [ {"floor":1, "points":[{"fx":...,"fy":...}, ...]}, ... ] }
  static Future<Map<String, dynamic>> readManualRoutes() async {
    final result = <String, dynamic>{};

    // First, load bundled routes from assets (if any)
    try {
      final assetText = await rootBundle.loadString(_manualRoutesAssetPath);
      final assetData = jsonDecode(assetText);
      if (assetData is Map<String, dynamic>) {
        result.addAll(assetData);
      }
    } catch (_) {
      // No bundled routes yet, that's ok
    }

    // Then, load and merge local routes (these override bundled ones)
    try {
      final f = await _manualRoutesFile();
      if (await f.exists()) {
        final localText = await f.readAsString();
        final localData = jsonDecode(localText);
        if (localData is Map<String, dynamic>) {
          result.addAll(localData); // Local overrides bundled
        }
      }
    } catch (_) {
      // No local routes yet
    }

    return result;
  }

  /// Write manual routes to local app storage.
  /// NOTE: To share routes via Git, manually copy the file from device to:
  ///       assets/data/manual_routes.json
  /// On Android: /data/data/com.example.emap_mobile/app_flutter/manual_routes.json
  /// Or use the exportManualRoutes() method to get the file path.
  static Future<void> writeManualRoutes(Map<String, dynamic> data) async {
    final f = await _manualRoutesFile();
    final txt = const JsonEncoder.withIndent('  ').convert(data);
    await f.writeAsString(txt, flush: true);
    print('Manual routes saved to: ${f.path}');
    print('To share via Git, copy this file to: $_manualRoutesAssetPath');
  }

  /// Get the local file path where manual routes are stored.
  /// Use this to manually copy the file to assets for Git commit.
  static Future<String> getManualRoutesPath() async {
    final f = await _manualRoutesFile();
    return f.path;
  }

  /// Export manual routes to Downloads folder for easy access.
  /// Returns the path to the exported file.
  static Future<String?> exportManualRoutesToDownloads() async {
    try {
      // Read the current manual routes (includes both bundled and local)
      final routes = await readManualRoutes();

      // If no routes, return null
      if (routes.isEmpty) {
        return null;
      }

      // Request storage permission for Android 10 and below
      if (Platform.isAndroid) {
        final sdkInt =
            int.tryParse(
              await Process.run('getprop', [
                'ro.build.version.sdk',
              ]).then((result) => result.stdout.toString().trim()),
            ) ??
            30;

        if (sdkInt <= 29) {
          // Android 10 and below need storage permission
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            print('Storage permission denied');
            return null;
          }
        }
      }

      // Save to public Downloads folder
      // For Android 10+, this path is accessible without special permissions
      final downloadsPath = '/storage/emulated/0/Download/manual_routes.json';
      final exportFile = File(downloadsPath);

      // Write the complete routes data
      final json = const JsonEncoder.withIndent('  ').convert(routes);
      await exportFile.writeAsString(json, flush: true);

      return downloadsPath;
    } catch (e) {
      print('Error exporting manual routes: $e');
      return null;
    }
  }

  /// Get the JSON content of manual routes as a string.
  /// Use this to copy/paste the content.
  static Future<String?> getManualRoutesContent() async {
    try {
      final f = await _manualRoutesFile();
      if (!await f.exists()) {
        return '{}';
      }
      return await f.readAsString();
    } catch (e) {
      print('Error reading manual routes: $e');
      return null;
    }
  }
}
