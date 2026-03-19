import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/list_config.dart';
import '../data_source/multi_context_data_source.dart';
import '../providers/context_provider.dart';
import '../providers/data_source_provider.dart';
import '../providers/items_provider.dart';
import '../providers/theme_provider.dart';

class DrawerMenu extends ConsumerWidget {
  final List<ListConfig> listConfigs;
  final String currentListUuid;
  final Function(String) onListSelected;
  final Function(String)? onConfigureList;
  final List<Widget>? drawerItems;
  final Widget? drawerHeader;
  final Future<void> Function(String contextId)? onContextChanged;
  final VoidCallback? onCreateList;
  final bool hasKanbanColumns;
  final bool isKanban;
  final VoidCallback? onKanbanSelected;

  const DrawerMenu({
    super.key,
    required this.listConfigs,
    required this.currentListUuid,
    required this.onListSelected,
    this.onConfigureList,
    this.drawerItems,
    this.drawerHeader,
    this.onContextChanged,
    this.onCreateList,
    this.hasKanbanColumns = false,
    this.isKanban = false,
    this.onKanbanSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contexts = ref.watch(dataContextsProvider).value ?? [];
    final currentContext = ref.watch(currentContextProvider);
    final themeMode = ref.watch(themeModeProvider);
    final counts = ref.watch(listCountsProvider).value ?? {};

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          drawerHeader ?? DrawerHeader(
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
          if (contexts.length > 1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButton<String>(
                value: currentContext?.id,
                isExpanded: true,
                hint: const Text('Select context'),
                items: contexts.map((ctx) {
                  return DropdownMenuItem<String>(
                    value: ctx.id,
                    child: Text(ctx.name),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value != null) {
                    if (onContextChanged != null) {
                      await onContextChanged!(value);
                    } else {
                      // Fallback: library handles internally (standalone use)
                      final ds = ref.read(dataSourceProvider);
                      if (ds is MultiContextDataSource) {
                        await ds.switchContext(value);
                        resetContextState(ref, defaultListId: ds.defaultListId);
                      }
                    }
                    // Close the drawer so it reopens with fresh widget state
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ),
            const Divider(),
          ],
          ...listConfigs.map((config) {
            final isSelected = currentListUuid == config.uuid;
            final count = counts[config.uuid] ?? 0;
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
                      '${config.name} ($count)',
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
              trailing: onConfigureList != null
                  ? IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: 'List settings',
                      onPressed: () {
                        Navigator.pop(context);
                        onConfigureList!(config.uuid);
                      },
                    )
                  : null,
              tileColor: isSelected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : null,
              onTap: () {
                onListSelected(config.uuid);
                Navigator.pop(context);
              },
            );
          }),
          if (hasKanbanColumns)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isKanban
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.view_kanban,
                      color: isKanban
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Board',
                      style: TextStyle(
                        color: isKanban
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: isKanban ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              tileColor: isKanban
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : null,
              onTap: () {
                Navigator.pop(context);
                onKanbanSelected?.call();
              },
            ),
          if (onCreateList != null)
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New list'),
              onTap: () {
                Navigator.pop(context);
                onCreateList!();
              },
            ),
          const Divider(),
          if (drawerItems != null && drawerItems!.isNotEmpty) ...[
            ...drawerItems!,
            const Divider(),
          ],
          ListTile(
            leading: Icon(
              themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
            ),
            title: Text(themeMode == ThemeMode.dark ? 'Dark mode' : 'Light mode'),
            onTap: () => toggleTheme(ref),
          ),
        ],
      ),
    );
  }
}
