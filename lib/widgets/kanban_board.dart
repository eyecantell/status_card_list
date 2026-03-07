import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_list_config.dart';
import '../models/list_config.dart';
import '../providers/actions_provider.dart';
import '../providers/items_provider.dart';
import '../providers/kanban_providers.dart';
import '../providers/lists_provider.dart';
import 'kanban_card.dart';

class KanbanBoard extends ConsumerWidget {
  final List<ListConfig> columns;
  final List<ListConfig> allConfigs;
  final CardListConfig? cardListConfig;
  final void Function(String listId, String itemId)? onItemTapped;

  const KanbanBoard({
    super.key,
    required this.columns,
    required this.allConfigs,
    this.cardListConfig,
    this.onItemTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(listCountsProvider).valueOrNull ?? {};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns.map((col) {
          return SizedBox(
            width: 280,
            child: Column(
              children: [
                _KanbanColumnHeader(
                  config: col,
                  count: counts[col.uuid] ?? 0,
                ),
                Expanded(
                  child: _KanbanColumn(
                    listConfig: col,
                    allConfigs: allConfigs,
                    cardListConfig: cardListConfig,
                    onItemTapped: onItemTapped,
                    onMove: (itemId, fromListId, targetListId) =>
                        _handleMove(context, ref, itemId, fromListId,
                            targetListId),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleMove(BuildContext context, WidgetRef ref, String itemId,
      String fromListId, String targetListId) async {
    final allConfigsList = ref.read(listConfigsProvider).valueOrNull ?? [];
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get item title before removing
    final cache = ref.read(itemCacheProvider);
    final item = cache[itemId];
    final itemTitle = item?.title ?? 'Item';

    final success = await ref.read(actionsProvider).moveItem(
          itemId,
          fromListId,
          targetListId,
        );

    if (success) {
      // Optimistic remove from source column
      ref
          .read(kanbanItemsProvider(fromListId).notifier)
          .removeItem(itemId);
      // Refetch target column
      ref.invalidate(kanbanItemsProvider(targetListId));

      final targetConfig = allConfigsList.cast<ListConfig?>().firstWhere(
            (c) => c!.uuid == targetListId,
            orElse: () => allConfigsList.first,
          );
      final buttonColor = isDark ? Colors.black87 : Colors.white;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                  child: Text(
                      '$itemTitle moved to ${targetConfig?.name ?? ""}')),
              const SizedBox(width: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: buttonColor,
                  side: BorderSide(color: buttonColor.withAlpha(180)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                ),
                onPressed: () async {
                  messenger.hideCurrentSnackBar();
                  final undone = await ref
                      .read(actionsProvider)
                      .moveItem(itemId, targetListId, fromListId);
                  if (undone) {
                    ref.invalidate(kanbanItemsProvider(fromListId));
                    ref.invalidate(kanbanItemsProvider(targetListId));
                  }
                },
                child: const Text('Undo',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _KanbanColumnHeader extends StatelessWidget {
  final ListConfig config;
  final int count;

  const _KanbanColumnHeader({required this.config, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: config.color, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              config.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: config.color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: config.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  final ListConfig listConfig;
  final List<ListConfig> allConfigs;
  final CardListConfig? cardListConfig;
  final void Function(String listId, String itemId)? onItemTapped;
  final void Function(String itemId, String fromListId, String targetListId)?
      onMove;

  const _KanbanColumn({
    required this.listConfig,
    required this.allConfigs,
    this.cardListConfig,
    this.onItemTapped,
    this.onMove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(kanbanItemsProvider(listConfig.uuid));

    return asyncItems.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 8),
              Text('Failed to load',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () =>
                    ref.invalidate(kanbanItemsProvider(listConfig.uuid)),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No notices',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
              ),
            ),
          );
        }

        return Column(
          children: [
            if (items.length >= 200)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                child: Text(
                  'Showing first 200',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return KanbanCard(
                    item: items[index],
                    listConfig: listConfig,
                    listId: listConfig.uuid,
                    allConfigs: allConfigs,
                    cardListConfig: cardListConfig,
                    onMove: onMove,
                    onTap: onItemTapped,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
