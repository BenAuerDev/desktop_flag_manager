part of 'app_list_item.dart';

// Widget for the ExpansionTile children for system entries
class _SystemDefaultControls {
  final DesktopEntry entry;
  final Set<String> thisEntryOps;

  const _SystemDefaultControls(
      {required this.entry, required this.thisEntryOps});

  List<Widget> build(BuildContext context, WidgetRef ref,
      Function(BuildContext, String, {bool isError}) showSnackBar) {
    final isCreating = thisEntryOps.contains('CREATE_OVERRIDE');
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          'File: ${entry.filePath}',
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const Text(
        'This is a system application. To modify flags, create a local override first.',
        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
      ),
      const SizedBox(height: 10),
      Center(
        child: isCreating
            ? const SizedBox(
                height: 40, child: Center(child: CircularProgressIndicator()))
            : ElevatedButton.icon(
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Create Local Override'),
                onPressed: () async {
                  final success = await ref
                      .read(appListProvider.notifier)
                      .createLocalOverride(entry);
                  if (!success && context.mounted) {
                    showSnackBar(context, 'Failed to create override',
                        isError: true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
      ),
    ];
  }
}
