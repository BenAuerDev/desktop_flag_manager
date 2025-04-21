import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../domain/desktop_entry.dart';
import 'managed_items.dart';
import 'desktop_file_parser.dart';

class LocalOverrideManager {
  final DesktopFileParser _parser;

  LocalOverrideManager() : _parser = DesktopFileParser();

  Future<DesktopEntry?> ensureLocalOverride(DesktopEntry entry) async {
    if (entry.isLocalOverride) return entry;

    String? localPath;
    try {
      final Directory localAppDir = await getApplicationSupportDirectory();
      localPath = p.join(localAppDir.parent.path, 'applications');
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting local application path: $e');
      return null;
    }

    final localDir = Directory(localPath);
    if (!await localDir.exists()) {
      try {
        await localDir.create(recursive: true);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error creating local directory $localPath: $e');
        }
        return null;
      }
    }

    final sourceFile = File(entry.filePath);
    final destinationPath = p.join(localPath, p.basename(entry.filePath));
    final destinationFile = File(destinationPath);

    if (!await destinationFile.exists()) {
      try {
        await sourceFile.copy(destinationPath);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error copying ${entry.filePath} to $destinationPath: $e');
        }
        return null;
      }
    }

    return await _parser.parseDesktopFile(destinationFile, true);
  }

  Future<void> updateManagedItem(
      DesktopEntry entry, ManagedItem item, bool addState) async {
    if (!entry.isLocalOverride) {
      if (kDebugMode) {
        debugPrint('Cannot modify system file directly: ${entry.filePath}');
      }
      return;
    }

    final file = File(entry.filePath);
    if (!await file.exists()) {
      if (kDebugMode) debugPrint('Local file not found: ${entry.filePath}');
      return;
    }

    final lines = await file.readAsLines();
    final newLines = <String>[];
    bool updated = false;

    for (final line in lines) {
      if (line.trim().startsWith('Exec=') && !updated) {
        String currentExec = line.substring(line.indexOf('=') + 1).trim();
        String newExec = currentExec; // Default to current if no change needed
        bool itemExists = entry.hasManagedItem(item);

        if (addState && !itemExists) {
          // Add the item
          newExec = _addItemToExec(currentExec, item);
          updated = true;
        } else if (!addState && itemExists) {
          // Remove the item
          newExec = _removeItemFromExec(currentExec, item);
          updated = true;
        }

        if (updated) {
          newLines.add('Exec=$newExec');
        } else {
          newLines.add(line); // Add original line if no update occurred
        }
      } else {
        newLines.add(line);
      }
    }

    if (updated) {
      try {
        // Ensure a newline at the end of the file
        final content = newLines.join('\n');
        await file
            .writeAsString(content.endsWith('\n') ? content : '$content\n');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error writing updated file ${entry.filePath}: $e');
        }
      }
    }
  }

  // Helper to add an item to the Exec string
  String _addItemToExec(String currentExec, ManagedItem item) {
    String execPrefix = '';
    String command = currentExec;
    String fieldCodes = '';

    // Separate env prefix
    final envMatch =
        RegExp(r'^(env\s+(?:[^=\s]+=[^\s]+\s+)*)(.*)$').firstMatch(currentExec);
    if (envMatch != null) {
      execPrefix = envMatch.group(1)!;
      command = envMatch.group(2)!;
    }

    // Separate field codes
    final fieldCodePattern = RegExp(r"\s+(%[fFuUickvm])(\s+(%[fFuUickvm]))*$");
    final fieldMatch = fieldCodePattern.firstMatch(command);
    if (fieldMatch != null) {
      fieldCodes = command.substring(fieldMatch.start);
      command = command.substring(0, fieldMatch.start).trim();
    }

    if (item.type == ManagedItemType.environmentVariable &&
        item.value != null) {
      final newVar = '${item.identifier}=${item.value}';
      if (execPrefix.isNotEmpty) {
        // Add to existing env block
        execPrefix = '$execPrefix$newVar ';
      } else {
        // Create new env block
        execPrefix = 'env $newVar ';
      }
    } else if (item.type == ManagedItemType.flag) {
      // Add flag after command, before field codes
      command = '$command ${item.identifier}'.trim();
    }

    return '$execPrefix$command$fieldCodes'.trim();
  }

  // Helper to remove an item from the Exec string
  String _removeItemFromExec(String currentExec, ManagedItem item) {
    if (item.type == ManagedItemType.environmentVariable &&
        item.value != null) {
      final varToRemove = RegExp.escape('${item.identifier}=${item.value}');
      // Remove VAR=value, potentially with surrounding space
      String newExec =
          currentExec.replaceFirst(RegExp(r'\b' + varToRemove + r'\s*\b'), '');
      // Clean up multiple spaces that might result
      newExec = newExec.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      // If the result is just "env", make it empty
      if (newExec == 'env') {
        newExec = '';
      }
      return newExec;
    } else if (item.type == ManagedItemType.flag) {
      // Use regex to remove the flag, handling spaces carefully
      final escapedIdentifier = RegExp.escape(item.identifier);
      final flagPattern = RegExp(r'(^|\s)' + escapedIdentifier + r'(?=\s|$)');
      return currentExec
          .replaceFirst(flagPattern, '')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();
    }
    return currentExec; // Should not happen
  }

  Future<bool> deleteLocalOverride(DesktopEntry entry) async {
    if (!entry.isLocalOverride) return false;

    final file = File(entry.filePath);
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting ${entry.filePath}: $e');
      return false;
    }
  }
}
