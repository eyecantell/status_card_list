import 'package:flutter/material.dart';
import '../item.dart';
import '../list_config.dart';

class DrawerMenu extends StatelessWidget {
  final List<ListConfig> listConfigs;
  final String currentList;
  final Map<String, List<Item>> itemLists;
  final Function(String) onListSelected;

  const DrawerMenu({
    super.key,
    required this.listConfigs,
    required this.currentList,
    required this.itemLists,
    required this.onListSelected,
  });

  IconData _getIconForList(String listName) {
    switch (listName) {
      case 'Review':
        return Icons.rate_review;
      case 'Saved':
        return Icons.bookmark;
      case 'Trash':
        return Icons.delete;
      default:
        return Icons.list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue[800]
                  : Colors.blue,
            ),
            child: const Text(
              'Task Lists',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ...listConfigs.map((config) {
            final isSelected = currentList == config.name;
            return ListTile(
              leading: Icon(
                _getIconForList(config.name),
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).iconTheme.color,
              ),
              title: Text(
                '${config.name} (${itemLists[config.name]?.length ?? 0})',
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              tileColor: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
              onTap: () {
                onListSelected(config.name);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}