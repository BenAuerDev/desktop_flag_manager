import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class DesktopDatabaseManager {
  Future<void> runUpdateDesktopDatabase() async {
    String? localPath;
    try {
      final Directory localAppDir = await getApplicationSupportDirectory();
      localPath = p.join(localAppDir.parent.path, 'applications');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting local application path for update-db: $e');
      }
      return;
    }

    try {
      final result = await Process.run('update-desktop-database', [localPath]);
      if (result.exitCode != 0) {
        if (kDebugMode) {
          debugPrint(
              'Error running update-desktop-database (Exit code: ${result.exitCode}):');
          debugPrint('stdout: ${result.stdout}');
          debugPrint('stderr: ${result.stderr}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Exception running update-desktop-database: $e');
      }
    }
  }
}
