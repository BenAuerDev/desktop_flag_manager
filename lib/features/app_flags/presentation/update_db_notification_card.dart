part of 'home_screen.dart';

// Widget for the "Update DB" notification card in the list
class _UpdateDbNotificationCard extends StatelessWidget {
  final VoidCallback onUpdatePressed;

  const _UpdateDbNotificationCard({required this.onUpdatePressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 1.0,
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(Icons.sync_problem_outlined,
            color: Theme.of(context).colorScheme.onTertiaryContainer),
        title: Text('Changes detected',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer)),
        subtitle: Text('Update desktop database?',
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onTertiaryContainer
                    .withAlpha(204))),
        trailing: TextButton(
          onPressed: onUpdatePressed,
          child: Text('UPDATE',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.bold)),
        ),
        dense: true,
      ),
    );
  }
}
