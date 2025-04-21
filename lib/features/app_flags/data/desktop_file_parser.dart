import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import '../domain/desktop_entry.dart';

class DesktopFileParser {
  Future<DesktopEntry?> parseDesktopFile(File file, bool isLocal) async {
    if (!await file.exists()) {
      return null;
    }

    String? name;
    String? exec;
    String? iconNameOrPath;
    bool noDisplay = false;
    bool inDesktopEntrySection = false;

    try {
      final lines = await file.readAsLines();
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) {
          continue;
        }

        if (trimmedLine == '[Desktop Entry]') {
          inDesktopEntrySection = true;
          continue;
        }

        if (trimmedLine.startsWith('[') && inDesktopEntrySection) {
          break;
        }

        if (inDesktopEntrySection) {
          if (trimmedLine.startsWith('Name=')) {
            name = trimmedLine.substring(5);
          } else if (trimmedLine.startsWith('Exec=')) {
            exec = trimmedLine.substring(5);
          } else if (trimmedLine.startsWith('NoDisplay=')) {
            noDisplay = trimmedLine.substring(10).toLowerCase() == 'true';
          } else if (trimmedLine.startsWith('Icon=')) {
            iconNameOrPath = trimmedLine.substring(5);
          }
        }

        if (name != null && exec != null && iconNameOrPath != null) {
          break;
        }
      }

      if (name != null && exec != null) {
        final id = p.basenameWithoutExtension(file.path);
        return DesktopEntry(
          id: id,
          name: name,
          exec: exec,
          filePath: file.path,
          isLocalOverride: isLocal,
          noDisplay: noDisplay,
          iconNameOrPath: iconNameOrPath,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error parsing desktop file ${file.path}: $e');
      }
    }

    return null;
  }
}
