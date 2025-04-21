part of 'home_screen.dart';

class _AppBarSearchAndFilter extends StatelessWidget
    implements PreferredSizeWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final AppFilterType currentFilter;
  final ValueChanged<AppFilterType> onFilterChanged;
  final VoidCallback onSearchCleared;

  const _AppBarSearchAndFilter({
    required this.searchController,
    required this.searchQuery,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.onSearchCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search apps...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search',
                      onPressed: onSearchCleared,
                    )
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            spacing: 8.0,
            children: <Widget>[
              FilterChip(
                label: const Text('All'),
                selected: currentFilter == AppFilterType.all,
                onSelected: (selected) {
                  if (selected) onFilterChanged(AppFilterType.all);
                },
              ),
              FilterChip(
                label: const Text('Local Only'),
                selected: currentFilter == AppFilterType.localOnly,
                onSelected: (selected) {
                  if (selected) onFilterChanged(AppFilterType.localOnly);
                },
                avatar: Icon(Icons.home_outlined,
                    color: currentFilter == AppFilterType.localOnly
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              FilterChip(
                label: const Text('System Only'),
                selected: currentFilter == AppFilterType.systemOnly,
                onSelected: (selected) {
                  if (selected) onFilterChanged(AppFilterType.systemOnly);
                },
                avatar: Icon(Icons.desktop_windows_outlined,
                    color: currentFilter == AppFilterType.systemOnly
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 2 + 16);
}
