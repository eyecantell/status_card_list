import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/list_config.dart';
import '../models/sort_mode.dart';
import '../providers/actions_provider.dart';
import '../providers/items_provider.dart';
import '../providers/lists_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/drawer_menu.dart';
import '../widgets/list_settings_dialog.dart';
import '../models/card_list_config.dart';
import '../status_card_list_example.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final CardListConfig? cardListConfig;

  const HomeScreen({super.key, this.cardListConfig});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleStatusChange(BuildContext context, item, String targetListUuid) async {
    final currentListId = ref.read(currentListIdProvider);
    final allConfigs = ref.read(listConfigsProvider).value ?? [];

    final success = await ref.read(actionsProvider).moveItem(
      item.id,
      currentListId,
      targetListUuid,
    );

    if (success && mounted) {
      final targetConfig = allConfigs.firstWhere(
        (c) => c.uuid == targetListUuid,
        orElse: () => allConfigs.first,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.title} moved to ${targetConfig.name}')),
      );
    }
  }

  void _handleReorder(int oldIndex, int newIndex) async {
    final currentListId = ref.read(currentListIdProvider);

    await ref.read(actionsProvider).reorderItems(
      currentListId,
      oldIndex,
      newIndex,
    );

    // Set sort mode to manual
    await ref.read(listConfigsProvider.notifier).setSortMode(
      currentListId,
      SortMode.manual,
    );
  }

  void _handleNavigateToItem(BuildContext context, String targetListUuid, String itemId) {
    navigateToItem(ref, targetListUuid, itemId);

    final allConfigs = ref.read(listConfigsProvider).value ?? [];
    final targetConfig = allConfigs.firstWhere(
      (c) => c.uuid == targetListUuid,
      orElse: () => allConfigs.first,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigated to ${targetConfig.name}')),
    );

    // Handle scroll after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final items = ref.read(itemsForCurrentListProvider);
      final targetIndex = items.indexWhere((i) => i.id == itemId);

      if (targetIndex >= 0 && _scrollController.hasClients) {
        final expandedItemId = ref.read(expandedItemIdProvider);
        final offset = CardDimensions.calculateScrollOffset(
          targetIndex,
          isExpanded: expandedItemId == itemId,
        );

        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _handleSwitchList(String listUuid) {
    ref.read(currentListIdProvider.notifier).state = listUuid;
    ref.read(expandedItemIdProvider.notifier).state = null;
    ref.read(navigatedItemIdProvider.notifier).state = null;
    // Refresh items for the new list
    ref.read(itemsProvider.notifier).refresh();
  }

  void _showSettingsDialog(BuildContext context, ListConfig config) {
    final allConfigs = ref.read(listConfigsProvider).value ?? [];

    showDialog(
      context: context,
      builder: (context) => ListSettingsDialog(
        listConfig: config,
        allConfigs: allConfigs,
        onSave: (updatedConfig) async {
          await ref.read(listConfigsProvider.notifier).updateConfig(updatedConfig);
        },
      ),
    );
  }

  void _handleExpand(String itemId) async {
    // Toggle expand state
    final currentExpanded = ref.read(expandedItemIdProvider);
    ref.read(expandedItemIdProvider.notifier).state =
        currentExpanded == itemId ? null : itemId;

    // Load detail if html is null
    final cache = ref.read(itemCacheProvider);
    final item = cache[itemId];
    if (item != null && item.html == null) {
      await ref.read(actionsProvider).loadItemDetail(itemId);
      // No refresh needed - itemsForCurrentListProvider watches itemCacheProvider
    }
  }

  void _setSortMode(SortMode mode) async {
    final currentListId = ref.read(currentListIdProvider);
    await ref.read(listConfigsProvider.notifier).setSortMode(currentListId, mode);
    // Refresh items with new sort mode
    ref.read(itemsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = ref.watch(currentListConfigProvider);
    final currentItems = ref.watch(itemsForCurrentListProvider);
    final allConfigs = ref.watch(listConfigsProvider).value ?? [];
    final itemCache = ref.watch(itemCacheProvider);
    final itemToListIndex = ref.watch(itemToListIndexProvider);
    final currentListId = ref.watch(currentListIdProvider);
    final expandedItemId = ref.watch(expandedItemIdProvider);
    final navigatedItemId = ref.watch(navigatedItemIdProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Show loading indicator while data is loading
    if (currentConfig == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: PopupMenuButton<String>(
                onSelected: _handleSwitchList,
                tooltip: 'Select list',
                color: Theme.of(context).cardTheme.color,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: currentConfig.color, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(currentConfig.icon, color: currentConfig.color),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${currentConfig.name} List',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: currentConfig.color, size: 20),
                    ],
                  ),
                ),
                itemBuilder: (context) => allConfigs.map((config) {
                  final isSelected = config.uuid == currentListId;
                  final count = itemToListIndex.values.where((id) => id == config.uuid).length;
                  return PopupMenuItem<String>(
                    value: config.uuid,
                    child: Row(
                      children: [
                        if (isSelected)
                          Icon(Icons.check, color: config.color, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Icon(config.icon, color: config.color),
                        const SizedBox(width: 8),
                        Text(
                          config.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($count)',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(context, currentConfig),
              tooltip: 'List Settings',
            ),
          ],
        ),
        actions: [
          DropdownButton<SortMode>(
            value: currentConfig.sortMode,
            icon: const Icon(Icons.sort),
            onChanged: (SortMode? newValue) {
              if (newValue != null) {
                _setSortMode(newValue);
              }
            },
            items: SortMode.values.map((SortMode mode) {
              String label;
              switch (mode) {
                case SortMode.dateAscending:
                  label = 'Date Ascending';
                case SortMode.dateDescending:
                  label = 'Date Descending';
                case SortMode.title:
                  label = 'Title';
                case SortMode.manual:
                  label = 'Manual';
                case SortMode.similarityDescending:
                  label = 'Best Match';
                case SortMode.deadlineSoonest:
                  label = 'Deadline Soonest';
                case SortMode.newest:
                  label = 'Newest';
              }
              return DropdownMenuItem<SortMode>(
                value: mode,
                child: Text(label),
              );
            }).toList(),
          ),
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => toggleTheme(ref),
          ),
        ],
      ),
      drawer: DrawerMenu(
        listConfigs: allConfigs,
        currentListUuid: currentListId,
        itemToListIndex: itemToListIndex,
        onListSelected: _handleSwitchList,
      ),
      body: Builder(
        builder: (BuildContext scaffoldContext) {
          return StatusCardListExample(
            items: currentItems,
            listConfig: currentConfig,
            onStatusChanged: (item, targetListUuid) =>
                _handleStatusChange(scaffoldContext, item, targetListUuid),
            onReorder: _handleReorder,
            allConfigs: allConfigs,
            itemMap: itemCache,
            itemToListIndex: itemToListIndex,
            onNavigateToItem: (targetListUuid, itemId) =>
                _handleNavigateToItem(scaffoldContext, targetListUuid, itemId),
            expandedItemId: expandedItemId,
            navigatedItemId: navigatedItemId,
            scrollController: _scrollController,
            onExpand: _handleExpand,
            cardListConfig: widget.cardListConfig,
          );
        },
      ),
    );
  }
}
