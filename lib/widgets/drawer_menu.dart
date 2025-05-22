import 'package:flutter/material.dart';
import '../item.dart';
import '../list_config.dart';

class DrawerMenu extends StatelessWidget {
  final List<ListConfig> listConfigs;
  final String currentListUuid;
  final Map<String, List<Item>> itemLists;
  final Function(String) onListSelected;

  const DrawerMenu({
    super.key,
    required this.listConfigs,
    required this.currentListUuid,
    required this.itemLists,
    required this.onListSelected,
  });

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
            final isSelected = currentListUuid == config.uuid;
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: config.color, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      config.icon,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : config.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${config.name} (${itemLists[config.uuid]?.length ?? 0})',
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              tileColor: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
              onTap: () {
                onListSelected(config.uuid);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}