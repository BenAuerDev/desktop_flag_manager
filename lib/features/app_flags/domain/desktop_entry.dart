import 'package:flutter/foundation.dart';
import '../data/managed_items.dart';

@immutable
class DesktopEntry {
  final String id;
  final String name;
  final String exec;
  final String filePath;
  final bool isLocalOverride;
  final bool noDisplay;
  final String? iconNameOrPath;

  const DesktopEntry({
    required this.id,
    required this.name,
    required this.exec,
    required this.filePath,
    required this.isLocalOverride,
    this.noDisplay = false,
    this.iconNameOrPath,
  });

  bool hasManagedItem(ManagedItem item) {
    String commandPart = exec.trim();
    final fieldCodes = ['%f', '%F', '%u', '%U', '%i', '%c', '%k', '%v', '%m'];

    // 1. Handle Environment Variables
    if (item.type == ManagedItemType.environmentVariable &&
        item.value != null) {
      final envPattern = RegExp(r'^env\s+.*\b' +
          RegExp.escape(item.identifier) +
          r'=' +
          RegExp.escape(item.value!) +
          r'\b');
      final envPatternSingle = RegExp(r'^env\s+' +
          RegExp.escape(item.identifier) +
          r'=' +
          RegExp.escape(item.value!) +
          r'\s+');
      // Check if exec starts with 'env' and contains the specific VAR=value pair
      return envPattern.hasMatch(commandPart) ||
          envPatternSingle.hasMatch(commandPart);
    }

    // 2. Handle Flags
    if (item.type == ManagedItemType.flag) {
      // Remove env prefix if it exists, to only check flags passed to the command
      commandPart = commandPart.replaceFirst(
          RegExp(r'^env\s+(?:[^=\s]+=[^\s]+\s+)*'), '');

      // Trim trailing field codes for checking flags
      bool codeRemoved;
      do {
        codeRemoved = false;
        for (final code in fieldCodes) {
          if (commandPart.endsWith(' $code')) {
            commandPart = commandPart
                .substring(0, commandPart.length - code.length - 1)
                .trim();
            codeRemoved = true;
            break;
          }
          // Handle case where field code might not have a preceding space (less common)
          if (commandPart.endsWith(code)) {
            commandPart = commandPart
                .substring(0, commandPart.length - code.length)
                .trim();
            codeRemoved = true;
            break;
          }
        }
      } while (codeRemoved);

      // Check if the flag exists as a whole word/argument
      // Escape the identifier for regex use, especially for flags with '='
      final escapedIdentifier = RegExp.escape(item.identifier);
      // Regex: boundary -> escaped flag -> boundary
      // Handles start/end of string or spaces as boundaries
      final flagPattern = RegExp(r'(^|\s)' + escapedIdentifier + r'(\s|$)');
      return flagPattern.hasMatch(commandPart);
    }

    return false; // Should not happen with current types
  }

  @override
  String toString() {
    return 'DesktopEntry{id: $id, name: $name, noDisplay: $noDisplay, exec: $exec, filePath: $filePath, isLocalOverride: $isLocalOverride}';
  }

  DesktopEntry copyWith({
    String? id,
    String? name,
    String? exec,
    String? filePath,
    bool? isLocalOverride,
    bool? noDisplay,
    String? iconNameOrPath,
  }) {
    return DesktopEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      exec: exec ?? this.exec,
      filePath: filePath ?? this.filePath,
      isLocalOverride: isLocalOverride ?? this.isLocalOverride,
      noDisplay: noDisplay ?? this.noDisplay,
      iconNameOrPath: iconNameOrPath ?? this.iconNameOrPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DesktopEntry &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath;

  @override
  int get hashCode => filePath.hashCode;
}
