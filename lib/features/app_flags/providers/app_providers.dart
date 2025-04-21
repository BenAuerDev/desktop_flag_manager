import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show immutable, kDebugMode;
import '../domain/desktop_entry.dart';
import '../data/desktop_service.dart' show DesktopService;
import '../data/managed_items.dart' show ManagedItem;
import 'package:path/path.dart' as p;
import '../domain/app_filter_type.dart';

final desktopServiceProvider = Provider<DesktopService>((ref) {
  return DesktopService();
});

@immutable
class AppListState {
  final List<DesktopEntry>? apps;
  final bool isLoading;
  final String? error;
  final bool needsDbUpdate;
  final Map<String, Set<String>> pendingOperations;
  final String searchQuery;
  final AppFilterType filterType;

  const AppListState({
    this.apps,
    this.isLoading = true,
    this.error,
    this.needsDbUpdate = false,
    this.pendingOperations = const {},
    this.searchQuery = '',
    this.filterType = AppFilterType.all,
  });

  AppListState copyWith({
    List<DesktopEntry>? apps,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? needsDbUpdate,
    Map<String, Set<String>>? pendingOperations,
    String? searchQuery,
    AppFilterType? filterType,
  }) {
    return AppListState(
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      needsDbUpdate: needsDbUpdate ?? this.needsDbUpdate,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      searchQuery: searchQuery ?? this.searchQuery,
      filterType: filterType ?? this.filterType,
    );
  }
}

Map<String, Set<String>> _addPendingOp(
    Map<String, Set<String>> current, String filePath, String opName) {
  final newMap = Map<String, Set<String>>.from(current);
  final currentOps = newMap[filePath] ?? <String>{};
  final newOps = Set<String>.from(currentOps)..add(opName);
  newMap[filePath] = newOps;
  return newMap;
}

Map<String, Set<String>> _removePendingOp(
    Map<String, Set<String>> current, String filePath, String opName) {
  final newMap = Map<String, Set<String>>.from(current);
  final currentOps = newMap[filePath];
  if (currentOps != null) {
    final newOps = Set<String>.from(currentOps)..remove(opName);
    if (newOps.isEmpty) {
      newMap.remove(filePath);
    } else {
      newMap[filePath] = newOps;
    }
  }
  return newMap;
}

class AppListNotifier extends StateNotifier<AppListState> {
  final DesktopService _desktopService;

  AppListNotifier(this._desktopService) : super(const AppListState()) {
    loadApps();
  }

  Future<void> loadApps() async {
    _desktopService.clearIconCache();

    state = state.copyWith(
        isLoading: true,
        clearError: true,
        needsDbUpdate: false,
        pendingOperations: {});
    try {
      final loadedApps = await _desktopService.discoverApps();
      if (!mounted) return;
      state = state.copyWith(apps: loadedApps, isLoading: false);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error loading apps in Notifier: $e\n$stackTrace");
      }
      if (!mounted) return;
      state = state.copyWith(
          error: 'Failed to load applications: $e',
          isLoading: false,
          apps: [],
          needsDbUpdate: false,
          pendingOperations: {});
    }
  }

  Future<bool> createLocalOverride(DesktopEntry entry) async {
    if (entry.isLocalOverride) return false;

    const opName = 'CREATE_OVERRIDE';
    state = state.copyWith(
        pendingOperations:
            _addPendingOp(state.pendingOperations, entry.filePath, opName));

    DesktopEntry? localEntryData;
    bool success = false;
    try {
      localEntryData = await _desktopService.ensureLocalOverride(entry);
      success = localEntryData != null;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
            error: "Failed to create override for ${entry.name}: $e");
      }
      success = false;
    } finally {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        state = state.copyWith(
            pendingOperations: _removePendingOp(
                state.pendingOperations, entry.filePath, opName));
      }
    }

    if (!mounted) return false;

    if (success && localEntryData != null) {
      state = state.copyWith(
        apps: state.apps?.map((app) {
          return app.filePath == entry.filePath ? localEntryData! : app;
        }).toList(),
        clearError: true,
        needsDbUpdate: true,
      );
      return true;
    } else {
      if (state.error == null) {
        state = state.copyWith(
            error:
                "Failed to create override for ${entry.name} (Unknown error)");
      }
      return false;
    }
  }

  Future<bool> deleteLocalOverride(DesktopEntry entry) async {
    if (!entry.isLocalOverride) return false;

    const opName = 'DELETE_OVERRIDE';
    state = state.copyWith(
        pendingOperations:
            _addPendingOp(state.pendingOperations, entry.filePath, opName));

    bool success = false;
    try {
      success = await _desktopService.deleteLocalOverride(entry);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
            error: "Failed to delete override for ${entry.name}: $e");
      }
      success = false;
    } finally {
      if (mounted) {
        state = state.copyWith(
            pendingOperations: _removePendingOp(
                state.pendingOperations, entry.filePath, opName));
      }
    }

    if (!mounted) return false;

    if (success) {
      final systemFileName = p.basename(entry.filePath);
      const systemPathDir = '/usr/share/applications';
      final systemFilePath = p.join(systemPathDir, systemFileName);
      final systemFile = File(systemFilePath);

      DesktopEntry? systemEntryData;
      if (await systemFile.exists()) {
        systemEntryData =
            await _desktopService.parseDesktopFile(systemFile, false);
      }

      if (!mounted) return false;

      final currentApps = state.apps ?? [];
      List<DesktopEntry> updatedApps;

      if (systemEntryData != null) {
        updatedApps = currentApps.map((app) {
          return app.filePath == entry.filePath ? systemEntryData! : app;
        }).toList();
      } else {
        updatedApps =
            currentApps.where((app) => app.filePath != entry.filePath).toList();
      }

      state = state.copyWith(
        apps: updatedApps,
        clearError: true,
        needsDbUpdate: true,
      );
      return true;
    } else {
      if (state.error == null) {
        state = state.copyWith(
            error:
                "Failed to delete override for ${entry.name} (Unknown error)");
      }
      return false;
    }
  }

  Future<bool> toggleManagedItem(DesktopEntry entry, ManagedItem item) async {
    if (!entry.isLocalOverride) return false;

    final opName = 'TOGGLE_${item.fullString}';
    state = state.copyWith(
        pendingOperations:
            _addPendingOp(state.pendingOperations, entry.filePath, opName));

    bool success = false;
    DesktopEntry? updatedEntryData;

    try {
      bool currentState = entry.hasManagedItem(item);
      bool addState = !currentState;
      await _desktopService.updateManagedItem(entry, item, addState);
      updatedEntryData =
          await _desktopService.parseDesktopFile(File(entry.filePath), true);
      success = updatedEntryData != null;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
            error:
                "Failed to write changes for ${item.identifier} for ${entry.name}: $e");
      }
      success = false;
    } finally {
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        state = state.copyWith(
            pendingOperations: _removePendingOp(
                state.pendingOperations, entry.filePath, opName));
      }
    }

    if (!mounted) return false;

    if (success && updatedEntryData != null) {
      state = state.copyWith(
        apps: state.apps?.map((app) {
          return app.filePath == entry.filePath ? updatedEntryData! : app;
        }).toList(),
        clearError: true,
        needsDbUpdate: true,
      );
      return true;
    } else {
      if (state.error == null) {
        state = state.copyWith(
            error:
                "Failed to update state after toggling ${item.identifier} for ${entry.name}");
      }
      return false;
    }
  }

  void clearDbUpdateNeededFlag() {
    if (mounted) {
      state = state.copyWith(needsDbUpdate: false);
    }
  }

  void setSearchQuery(String query) {
    if (!mounted) return;
    state = state.copyWith(searchQuery: query);
  }

  void setFilterType(AppFilterType filter) {
    if (!mounted) return;
    state = state.copyWith(filterType: filter);
  }
}

final appListProvider =
    StateNotifierProvider<AppListNotifier, AppListState>((ref) {
  final desktopService = ref.watch(desktopServiceProvider);
  return AppListNotifier(desktopService);
});

final iconPathProvider =
    FutureProvider.family<String?, String>((ref, iconNameOrPath) async {
  if (iconNameOrPath.isEmpty) {
    return null;
  }
  final desktopService = ref.watch(desktopServiceProvider);
  return await desktopService.resolveIconPath(iconNameOrPath);
});

final filteredAppListProvider = Provider<List<DesktopEntry>>((ref) {
  final state = ref.watch(appListProvider);

  final apps = state.apps ?? [];
  final searchQuery = state.searchQuery;
  final filterType = state.filterType;

  final List<DesktopEntry> enumFilteredApps;
  switch (filterType) {
    case AppFilterType.localOnly:
      enumFilteredApps = apps.where((app) => app.isLocalOverride).toList();
      break;
    case AppFilterType.systemOnly:
      enumFilteredApps = apps.where((app) => !app.isLocalOverride).toList();
      break;
    case AppFilterType.all:
      enumFilteredApps = apps;
      break;
  }

  if (searchQuery.isEmpty) {
    return enumFilteredApps;
  } else {
    final lowerCaseQuery = searchQuery.toLowerCase();
    return enumFilteredApps
        .where((app) => app.name.toLowerCase().contains(lowerCaseQuery))
        .toList();
  }
});
