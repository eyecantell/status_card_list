import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/list_config.dart';
import '../models/sort_option.dart';
import '../providers/actions_provider.dart';
import '../providers/context_provider.dart';
import '../providers/data_source_provider.dart';
import '../providers/items_provider.dart';
import '../providers/lists_provider.dart';
import '../providers/navigation_provider.dart';
import '../data_source/multi_context_data_source.dart';
import '../providers/kanban_providers.dart';
import '../providers/view_mode_provider.dart';
import '../widgets/drawer_menu.dart';
import '../widgets/kanban_board.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _scrollTargetKey = GlobalKey();
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _startSearch() {
    setState(() { _isSearching = true; });
  }

  void _stopSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() { _isSearching = false; });
    ref.read(searchQueryProvider.notifier).state = null;
    ref.read(itemsProvider.notifier).refresh();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final query = value.trim().isEmpty ? null : value.trim();
      ref.read(searchQueryProvider.notifier).state = query;
      ref.read(itemsProvider.notifier).refresh();
    });
  }

  void _handleStatusChange(BuildContext context, item, String targetListUuid) async {
    final currentListId = ref.read(currentListIdProvider);
    final allConfigs = ref.read(listConfigsProvider).value ?? [];
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.read(expandedItemIdProvider.notifier).state = null;

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
      final buttonColor = isDark ? Colors.black87 : Colors.white;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text('${item.title} moved to ${targetConfig.name}')),
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: buttonColor,
                  side: BorderSide(color: buttonColor.withAlpha(180)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                onPressed: () async {
                  messenger.hideCurrentSnackBar();
                  final success = await ref.read(actionsProvider).moveItem(
                    item.id,
                    targetListUuid,
                    currentListId,
                  );
                  if (success && mounted) {
                    ref.read(itemsProvider.notifier).refresh();
                  }
                },
                child: const Text('Undo', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
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
      'manual',
    );
  }

  void _handleNavigateToItem(BuildContext context, String targetListUuid, String itemId) async {
    final allConfigs = ref.read(listConfigsProvider).value ?? [];
    final targetConfig = allConfigs.firstWhere(
      (c) => c.uuid == targetListUuid,
      orElse: () => allConfigs.first,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigated to ${targetConfig.name}')),
    );

    await navigateToItem(ref, targetListUuid, itemId);
    // Scroll is handled reactively via ref.listen on pendingScrollItemIdProvider in build()
  }

  void _handleSwitchList(String listUuid) {
    if (listUuid == '__create_new__') {
      widget.cardListConfig?.onCreateList?.call();
      return;
    }
    ScaffoldMessenger.of(context).clearSnackBars();
    // Exit search mode when switching lists
    if (_isSearching) _stopSearch();
    // Switch to list view when a list is explicitly selected
    ref.read(viewModeProvider.notifier).set('list');
    ref.read(currentListIdProvider.notifier).state = listUuid;
    ref.read(expandedItemIdProvider.notifier).state = null;
    ref.read(navigatedItemIdProvider.notifier).state = null;
    // Refresh items for the new list
    ref.read(itemsProvider.notifier).refresh();
  }

  void _showSettingsDialog(BuildContext context, ListConfig config) {
    final allConfigs = ref.read(listConfigsProvider).value ?? [];
    final isDeletable = widget.cardListConfig?.isListDeletable?.call(config) ?? false;

    showDialog(
      context: context,
      builder: (context) => ListSettingsDialog(
        listConfig: config,
        allConfigs: allConfigs,
        isDeletable: isDeletable,
        onDelete: isDeletable
            ? () => widget.cardListConfig?.onDeleteList?.call(config.uuid)
            : null,
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

  void _setSortMode(String modeId) async {
    final currentListId = ref.read(currentListIdProvider);
    await ref.read(listConfigsProvider.notifier).setSortMode(currentListId, modeId);
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
    final counts = ref.watch(listCountsProvider).value ?? {};
    final currentListId = ref.watch(currentListIdProvider);
    final expandedItemId = ref.watch(expandedItemIdProvider);
    final navigatedItemId = ref.watch(navigatedItemIdProvider);
    final pendingScrollItemId = ref.watch(pendingScrollItemIdProvider);
    final viewMode = ref.watch(viewModeProvider);
    final kanbanColumns = ref.watch(kanbanColumnsProvider);
    final isKanban = viewMode == 'kanban' && kanbanColumns.isNotEmpty;

    // Reactively scroll to item when pendingScrollItemIdProvider is set (e.g., deep links)
    ref.listen<String?>(pendingScrollItemIdProvider, (_, itemId) {
      if (itemId == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _scrollTargetKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.2,
          );
        }
        clearPendingScroll(ref);
      });
    });

    // Show loading or error state while data is loading
    if (currentConfig == null) {
      final listConfigsState = ref.watch(listConfigsProvider);
      if (listConfigsState.hasError) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load lists',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${listConfigsState.error}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(listConfigsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }
      // Loaded successfully but no lists exist for this context
      if (allConfigs.isEmpty && listConfigsState.hasValue) {
        return Scaffold(
          drawer: DrawerMenu(
            listConfigs: const [],
            currentListUuid: '',
            onListSelected: (_) {},
            drawerItems: widget.cardListConfig?.drawerItems,
            drawerHeader: widget.cardListConfig?.drawerHeader,
            onContextChanged: widget.cardListConfig?.onContextChanged,
            onCreateList: widget.cardListConfig?.onCreateList,
          ),
          appBar: AppBar(title: const Text('No Lists')),
          body: const Center(
            child: Text('No lists available for this company.'),
          ),
        );
      }
      // Still loading
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _stopSearch,
              )
            : null,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search notices...',
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
              )
            : Builder(
          builder: (context) {
            final showLabels = MediaQuery.sizeOf(context).width >= 600;
            return Row(
          children: [
              PopupMenuButton<String>(
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
                      if (showLabels) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            currentConfig.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Icon(Icons.arrow_drop_down, color: currentConfig.color, size: 20),
                    ],
                  ),
                ),
                itemBuilder: (context) {
                  final items = allConfigs.map((config) {
                    final isSelected = config.uuid == currentListId;
                    final count = counts[config.uuid] ?? 0;
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
                  }).toList();
                  if (widget.cardListConfig?.onCreateList != null) {
                    items.add(const PopupMenuItem<String>(
                      enabled: false,
                      height: 1,
                      child: Divider(),
                    ));
                    items.add(const PopupMenuItem<String>(
                      value: '__create_new__',
                      child: Row(
                        children: [
                          SizedBox(width: 18),
                          SizedBox(width: 8),
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text('New list'),
                        ],
                      ),
                    ));
                  }
                  return items;
                },
              ),
            if (isKanban)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Board',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            Expanded(
              child: Center(
                child: _CompanySelector(
                  onContextChanged: widget.cardListConfig?.onContextChanged,
                  showLabel: showLabels,
                ),
              ),
            ),
          ],
        );
          },
        ),
        actions: _isSearching ? null : [
          if (kanbanColumns.isNotEmpty)
            IconButton(
              icon: Icon(isKanban ? Icons.view_list : Icons.view_kanban),
              tooltip: isKanban ? 'List view' : 'Board view',
              onPressed: () => ref.read(viewModeProvider.notifier).toggle(),
            ),
          if (!isKanban && widget.cardListConfig?.searchEnabled == true)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: _startSearch,
            ),
          if (!isKanban && widget.cardListConfig?.appBarActionsBuilder != null)
            ...widget.cardListConfig!.appBarActionsBuilder!(context, currentListId),
          if (!isKanban) PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort order',
            color: Theme.of(context).cardTheme.color,
            onSelected: _setSortMode,
            itemBuilder: (context) {
              final sortOptions = widget.cardListConfig?.sortOptions ?? SortOption.defaults;
              return sortOptions.map((option) {
                final isSelected = option.id == currentConfig.sortMode;
                return PopupMenuItem<String>(
                  value: option.id,
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(Icons.check, color: currentConfig.color, size: 18)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(
                        option.label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      drawer: DrawerMenu(
        listConfigs: allConfigs,
        currentListUuid: currentListId,
        onListSelected: _handleSwitchList,
        drawerItems: widget.cardListConfig?.drawerItems,
        drawerHeader: widget.cardListConfig?.drawerHeader,
        onContextChanged: widget.cardListConfig?.onContextChanged,
        onCreateList: widget.cardListConfig?.onCreateList,
        onConfigureList: (uuid) {
          final config = allConfigs.firstWhere(
            (c) => c.uuid == uuid,
            orElse: () => allConfigs.first,
          );
          _showSettingsDialog(context, config);
        },
      ),
      body: isKanban
          ? KanbanBoard(
              columns: kanbanColumns,
              allConfigs: allConfigs,
              cardListConfig: widget.cardListConfig,
              onItemTapped: (listId, itemId) {
                ref.read(viewModeProvider.notifier).set('list');
                navigateToItem(ref, listId, itemId);
              },
            )
          : Builder(
        builder: (BuildContext scaffoldContext) {
          final searchQuery = ref.watch(searchQueryProvider);
          if (searchQuery != null && searchQuery.isNotEmpty && currentItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    'No results for "$searchQuery"',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }
          // Empty state (non-search) — only when data is loaded (not during loading)
          final rawItemsState = ref.watch(itemsProvider);
          if (currentItems.isEmpty &&
              rawItemsState is AsyncData &&
              widget.cardListConfig?.emptyStateBuilder != null) {
            return widget.cardListConfig!.emptyStateBuilder!(
              context, currentConfig!, allConfigs, counts,
            );
          }
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
            scrollTargetItemId: pendingScrollItemId,
            scrollTargetKey: pendingScrollItemId != null ? _scrollTargetKey : null,
          );
        },
      ),
    );
  }
}

class _CompanySelector extends ConsumerWidget {
  final Future<void> Function(String contextId)? onContextChanged;
  final bool showLabel;

  const _CompanySelector({this.onContextChanged, this.showLabel = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contexts = ref.watch(dataContextsProvider).value ?? [];
    final currentContext = ref.watch(currentContextProvider);

    if (contexts.isEmpty) return const SizedBox.shrink();

    final enabled = contexts.length > 1;

    return Opacity(
      opacity: enabled ? 1.0 : 0.7,
      child: PopupMenuButton<String>(
        enabled: enabled,
        tooltip: enabled ? 'Switch company' : currentContext?.name ?? '',
        color: Theme.of(context).cardTheme.color,
        onSelected: (value) async {
          if (onContextChanged != null) {
            await onContextChanged!(value);
          } else {
            final ds = ref.read(dataSourceProvider);
            if (ds is MultiContextDataSource) {
              await ds.switchContext(value);
              resetContextState(ref, defaultListId: ds.defaultListId);
            }
          }
        },
        itemBuilder: (context) => contexts.map((ctx) {
          final isSelected = ctx.id == currentContext?.id;
          return PopupMenuItem<String>(
            value: ctx.id,
            child: Row(
              children: [
                if (isSelected)
                  Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(
                  ctx.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.business, size: 18),
                if (showLabel) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      currentContext?.name ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
                if (enabled) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
