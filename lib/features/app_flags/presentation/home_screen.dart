import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../providers/app_providers.dart';
import 'widgets/app_list_item.dart';
import '../domain/app_filter_type.dart';
import '../data/managed_items.dart' show ManagedItems;

part 'app_bar_search_filter.dart';
part 'update_db_notification_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        final newQuery = _searchController.text;
        if (newQuery != ref.read(appListProvider).searchQuery) {
          ref.read(appListProvider.notifier).setSearchQuery(newQuery);
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runUpdateDb() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Running update-desktop-database... This may take a moment.'),
        duration: Duration(seconds: 3),
      ),
    );
    try {
      await ref.read(desktopServiceProvider).runUpdateDesktopDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Desktop database update command finished.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print("Error running update-db manually: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running update-desktop-database: $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
    ref.read(appListProvider.notifier).clearDbUpdateNeededFlag();
  }

  void _showInfoDialog() {
    final items = ManagedItems.items;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About Desktop Flag Manager'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'This application allows you to manage specific command-line flags for Linux desktop applications by creating local overrides of their .desktop files.',
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Managed Flags/Variables:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...items
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ${item.fullString}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                const SizedBox(height: 16),
                const Text(
                  'Changes require updating the desktop database, which can sometimes take a moment.',
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appListState = ref.watch(appListProvider);
    final needsDbUpdate = appListState.needsDbUpdate;
    final isLoading = appListState.isLoading;
    final currentFilter = appListState.filterType;
    final searchQuery = appListState.searchQuery;

    final filteredApps = ref.watch(filteredAppListProvider);

    final totalAppCount = appListState.apps?.length ?? 0;

    const PageStorageKey listViewKey = PageStorageKey('appList');

    final appListNotifier = ref.read(appListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showInfoDialog,
          tooltip: 'About this app',
        ),
        title: const Text('Desktop Flag Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: appListNotifier.loadApps,
            tooltip: 'Refresh App List',
          ),
        ],
        bottom: _AppBarSearchAndFilter(
          searchController: _searchController,
          searchQuery: searchQuery,
          currentFilter: currentFilter,
          onFilterChanged: appListNotifier.setFilterType,
          onSearchCleared: () {
            _searchController.clear();
            appListNotifier.setSearchQuery('');
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appListState.apps == null
              ? const Center(child: Text('Initializing...'))
              : totalAppCount == 0
                  ? const Center(child: Text('''No applications found.
Check console for errors if this is unexpected.'''))
                  : filteredApps.isEmpty && currentFilter != AppFilterType.all
                      ? Center(
                          child: Text(
                              'No applications found matching the filter "${currentFilter.name}".'))
                      : filteredApps.isEmpty && searchQuery.isNotEmpty
                          ? Center(
                              child: Text(
                                  'No apps found matching "$searchQuery".'))
                          : PageStorage(
                              bucket: PageStorage.of(context),
                              child: ListView.builder(
                                key: listViewKey,
                                padding: const EdgeInsets.only(
                                    top: 8.0, bottom: 8.0),
                                itemCount: filteredApps.length +
                                    (needsDbUpdate ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (needsDbUpdate && index == 0) {
                                    return _UpdateDbNotificationCard(
                                      onUpdatePressed: _runUpdateDb,
                                    );
                                  }
                                  final appIndex =
                                      needsDbUpdate ? index - 1 : index;
                                  final app = filteredApps[appIndex];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 2.0),
                                    child: AppListItem(
                                      key: ValueKey(app.id),
                                      entry: app,
                                    ),
                                  );
                                },
                              ),
                            ),
    );
  }
}
