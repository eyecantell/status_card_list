import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/list_config.dart';
import '../data_source/multi_context_data_source.dart';
import '../providers/context_provider.dart';
import '../providers/data_source_provider.dart';
import '../providers/items_provider.dart';
import '../providers/lists_provider.dart';
import '../providers/theme_provider.dart';

class DrawerMenu extends ConsumerWidget {
  final List<ListConfig> listConfigs;
  final String currentListUuid;
  final Function(String) onListSelected;
  final Function(String)? onConfigureList;

  const DrawerMenu({
    super.key,
    required this.listConfigs,
    required this.currentListUuid,
    required this.onListSelected,
    this.onConfigureList,
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
                    final ds = ref.read(dataSourceProvider);
                    if (ds is MultiContextDataSource) {
                      await ds.switchContext(value);
                      ref.invalidate(listConfigsProvider);
                      ref.invalidate(itemsProvider);
                      ref.invalidate(dataContextsProvider);
                    }
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
          const Divider(),
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
