import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../domain/desktop_entry.dart';
import 'managed_items.dart';
import 'desktop_file_parser.dart';
import 'icon_resolver.dart';
import 'local_override_manager.dart';
import 'desktop_database_manager.dart';

class DesktopService {
  final DesktopFileParser _parser;
  final IconResolver _iconResolver;
  final LocalOverrideManager _overrideManager;
  final DesktopDatabaseManager _dbManager;

  DesktopService()
      : _parser = DesktopFileParser(),
        _iconResolver = IconResolver(),
        _overrideManager = LocalOverrideManager(),
        _dbManager = DesktopDatabaseManager();

  // Expose the managed items list
  static List<ManagedItem> get managedItems => ManagedItems.items;

  Future<List<DesktopEntry>> discoverApps() async {
    final Map<String, DesktopEntry> entries = {};

    const systemPath = '/usr/share/applications';
    String? localPath;
    try {
      final Directory localAppDirInstance =
          await getApplicationSupportDirectory();
      localPath = p.join(localAppDirInstance.parent.path, 'applications');
    } catch (e) {
      if (kDebugMode) debugPrint("Error getting local application path: $e");
      localPath = null;
    }

    final systemDir = Directory(systemPath);
    final localDir = localPath != null ? Directory(localPath) : null;

    List<FileSystemEntity> systemFiles = [];
    if (await systemDir.exists()) {
      systemFiles = systemDir
          .listSync()
          .where((f) => f.path.endsWith('.desktop'))
          .toList();
    }

    List<FileSystemEntity> localFiles = [];
    if (localDir != null && await localDir.exists()) {
      localFiles = localDir
          .listSync()
          .where((f) => f.path.endsWith('.desktop'))
          .toList();
    }

    Future<void> processFiles(
        List<FileSystemEntity> files, bool isLocal) async {
      for (final fileEntity in files) {
        if (fileEntity is File) {
          final entry = await _parser.parseDesktopFile(fileEntity, isLocal);
          if (entry != null) {
            if (isLocal || !entries.containsKey(entry.id)) {
              entries[entry.id] = entry;
            }
          }
        }
      }
    }

    await processFiles(systemFiles, false);
    await processFiles(localFiles, true);

    final appList = entries.values.where((entry) => !entry.noDisplay).toList();
    appList
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return appList;
  }

  void clearIconCache() {
    _iconResolver.clearCache();
  }

  Future<DesktopEntry?> parseDesktopFile(File file, bool isLocal) async {
    return _parser.parseDesktopFile(file, isLocal);
  }

  Future<DesktopEntry?> ensureLocalOverride(DesktopEntry entry) async {
    return _overrideManager.ensureLocalOverride(entry);
  }

  Future<void> updateManagedItem(
      DesktopEntry entry, ManagedItem item, bool addState) async {
    await _overrideManager.updateManagedItem(entry, item, addState);
  }

  Future<bool> deleteLocalOverride(DesktopEntry entry) async {
    return _overrideManager.deleteLocalOverride(entry);
  }

  Future<String?> resolveIconPath(String iconNameOrPath) async {
    return _iconResolver.resolveIconPath(iconNameOrPath);
  }

  Future<void> runUpdateDesktopDatabase() async {
    await _dbManager.runUpdateDesktopDatabase();
  }
}
