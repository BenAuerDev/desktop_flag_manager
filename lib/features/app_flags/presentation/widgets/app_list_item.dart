import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import '../../domain/desktop_entry.dart';
import '../../providers/app_providers.dart';
import '../../data/managed_items.dart' show ManagedItem, ManagedItems;

part 'app_icon.dart';
part 'local_override_controls.dart';
part 'system_default_controls.dart';

class AppListItem extends ConsumerWidget {
  final DesktopEntry entry;

  const AppListItem({
    super.key,
    required this.entry,
  });

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingOps =
        ref.watch(appListProvider.select((s) => s.pendingOperations));
    final thisEntryOps = pendingOps[entry.filePath] ?? <String>{};

    final Color? titleColor = entry.isLocalOverride ? Colors.blue[700] : null;
    final String subtitleText = entry.isLocalOverride
        ? 'Local override exists'
        : 'Using system default';

    return ExpansionTile(
      key: PageStorageKey(entry.id),
      leading: _AppIcon(iconNameOrPath: entry.iconNameOrPath ?? ''),
      title: Text(entry.name, style: TextStyle(color: titleColor)),
      subtitle: Text(subtitleText, style: const TextStyle(fontSize: 12)),
      childrenPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: entry.isLocalOverride
          ? _LocalOverrideControls(entry: entry, thisEntryOps: thisEntryOps)
              .build(context, ref, _showSnackBar)
          : _SystemDefaultControls(entry: entry, thisEntryOps: thisEntryOps)
              .build(context, ref, _showSnackBar),
    );
  }
}
