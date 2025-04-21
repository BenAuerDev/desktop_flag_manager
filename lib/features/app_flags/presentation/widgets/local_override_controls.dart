part of 'app_list_item.dart';

class _LocalOverrideControls {
  final DesktopEntry entry;
  final Set<String> thisEntryOps;

  const _LocalOverrideControls(
      {required this.entry, required this.thisEntryOps});

  // Helper to show description dialog
  void _showItemDescription(BuildContext context, ManagedItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.fullString),
        content: Text(item.description),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  List<Widget> build(
      BuildContext context, WidgetRef ref, Function showSnackBar) {
    final notifier = ref.read(appListProvider.notifier);
    // Get the list of managed items
    final managedItems = ManagedItems.items;

    return [
      const Text('Manage Flags/Variables:', style: TextStyle(fontSize: 16)),
      const SizedBox(height: 8.0),
      // Generate toggles for each managed item
      ...managedItems.map((item) {
        final opName = 'TOGGLE_${item.fullString}';
        final isItemPending = thisEntryOps.contains(opName);
        final bool currentValue = entry.hasManagedItem(item);

        return Row(
          children: [
            // Help Icon
            IconButton(
              icon: const Icon(Icons.help_outline, size: 18),
              tooltip: 'What is ${item.identifier}?',
              onPressed: isItemPending
                  ? null // Disable help when operation is pending
                  : () => _showItemDescription(context, item),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.only(right: 4),
            ),
            // Item Identifier Text
            Expanded(
              child: Text(
                item.fullString,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Loading Indicator or Switch
            isItemPending
                ? const SizedBox(
                    width: 48, // Same width as Switch
                    height: 24,
                    child: Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : Switch(
                    value: currentValue,
                    onChanged: (newValue) async {
                      final success =
                          await notifier.toggleManagedItem(entry, item);
                      if (!success && context.mounted) {
                        showSnackBar(
                          context,
                          ref.read(appListProvider).error ??
                              'Failed to toggle ${item.identifier}',
                          isError: true,
                        );
                      }
                    },
                  ),
          ],
        );
      }).toList(),
      const SizedBox(height: 16.0),
      const Divider(),
      const SizedBox(height: 16.0),
      Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete Local Override'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: thisEntryOps.contains('DELETE_OVERRIDE')
              ? null
              : () async {
                  final success = await notifier.deleteLocalOverride(entry);
                  if (!success && context.mounted) {
                    showSnackBar(
                      context,
                      ref.read(appListProvider).error ??
                          'Failed to delete override',
                      isError: true,
                    );
                  }
                  // No need to show success snackbar, list updates visually
                },
        ),
      ),
      // Show spinner next to delete button if pending
      if (thisEntryOps.contains('DELETE_OVERRIDE'))
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
    ];
  }
}
