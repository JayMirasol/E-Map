import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';

/// Helper class to export/import manual routes
class ManualRoutesBackup {
  /// Export manual_routes.json to phone storage and share
  static Future<void> exportManualRoutes(BuildContext context, Map<String, dynamic> manualRoutes) async {
    try {
      // Get external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _showError(context, 'Cannot access storage');
        return;
      }

      // Create backup file
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'manual_routes_backup_$timestamp.json';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      // Write JSON data
      final jsonString = jsonEncode(manualRoutes);
      await file.writeAsString(jsonString);

      // Show success and share
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported: $fileName'),
          duration: Duration(seconds: 2),
        ),
      );

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Manual Routes Backup',
        text: 'E-Map Manual Routes - ${manualRoutes.length} routes',
      );
    } catch (e) {
      _showError(context, 'Export failed: $e');
    }
  }

  /// Import manual_routes.json from file picker
  static Future<Map<String, dynamic>?> importManualRoutes(BuildContext context) async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        _showError(context, 'Cannot read file path');
        return null;
      }

      // Read and parse JSON
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${data.length} routes successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      return data;
    } catch (e) {
      _showError(context, 'Import failed: $e');
      return null;
    }
  }

  /// Export only specific building routes (smaller file)
  static Future<void> exportBuildingRoutes(
    BuildContext context,
    Map<String, dynamic> manualRoutes,
    String buildingFilter, // e.g., "MAIN", "NGO", "PAGCOR"
  ) async {
    try {
      // Filter routes by building
      final filteredRoutes = Map<String, dynamic>.from(
        manualRoutes.entries
            .where((entry) => entry.key.contains(buildingFilter))
            .fold<Map<String, dynamic>>({}, (map, entry) {
          map[entry.key] = entry.value;
          return map;
        }),
      );

      if (filteredRoutes.isEmpty) {
        _showError(context, 'No routes found for $buildingFilter');
        return;
      }

      // Export filtered routes
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _showError(context, 'Cannot access storage');
        return;
      }

      final fileName = 'manual_routes_${buildingFilter.toLowerCase()}.json';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      final jsonString = jsonEncode(filteredRoutes);
      await file.writeAsString(jsonString);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${filteredRoutes.length} $buildingFilter routes'),
          duration: Duration(seconds: 2),
        ),
      );

      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      _showError(context, 'Export failed: $e');
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
