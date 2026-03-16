import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../models/list_config.dart';
import 'data_source_provider.dart';
import 'items_provider.dart';
import 'lists_provider.dart';

/// All lists as kanban columns. Lists with stageOrder sort first (ascending),
/// then remaining lists in their original order.
final kanbanColumnsProvider = Provider<List<ListConfig>>((ref) {
  final configs = ref.watch(visibleListConfigsProvider);
  final staged = configs.where((c) => c.stageOrder != null).toList()
    ..sort((a, b) => a.stageOrder!.compareTo(b.stageOrder!));
  final unstaged = configs.where((c) => c.stageOrder == null).toList();
  return [...staged, ...unstaged];
});

/// Per-column items provider, keyed by list ID. AutoDispose ensures cleanup.
final kanbanItemsProvider = AutoDisposeAsyncNotifierProvider.family<
    KanbanColumnNotifier, List<Item>, String>(
  KanbanColumnNotifier.new,
);

class KanbanColumnNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Item>, String> {
  @override
  Future<List<Item>> build(String arg) async {
    return _load();
  }

  Future<List<Item>> _load() async {
    final listId = arg;
    final dataSource = ref.read(dataSourceProvider);

    // Kanban always uses manual sort order, independent of list view's sort mode.
    // This ensures drag-to-reorder persists even when the list view sort changes.
    final page = await dataSource.loadItems(
      listId: listId,
      sortMode: 'manual',
      limit: 200,
    );

    // Update shared caches
    final indexUpdate = <String, String>{};
    ref.read(itemCacheProvider.notifier).update((cache) {
      final updated = Map<String, Item>.from(cache);
      for (final item in page.items) {
        final existing = updated[item.id];
        if (existing != null && existing.html != null) {
          updated[item.id] = existing.copyWith(
            status: item.status,
            subtitle: item.subtitle,
            dueDate: item.dueDate,
            relatedItemIds: item.relatedItemIds,
            extra: item.extra,
          );
        } else {
          updated[item.id] = item;
        }
        indexUpdate[item.id] = listId;
      }
      return updated;
    });
    ref.read(itemToListIndexProvider.notifier).update((state) =>
        {...state, ...indexUpdate});

    return page.items;
  }

  void removeItem(String itemId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
        current.where((item) => item.id != itemId).toList());
  }

  Future<void> reorderItem(int oldIndex, int newIndex) async {
    final items = state.valueOrNull ?? [];
    if (oldIndex >= items.length) return;

    final adjustedNew = oldIndex < newIndex ? newIndex - 1 : newIndex;

    // Optimistic local reorder
    final reordered = List<Item>.from(items);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(adjustedNew, item);
    state = AsyncValue.data(reordered);

    // Persist to server
    final listId = arg;
    final dataSource = ref.read(dataSourceProvider);
    try {
      await dataSource.updateItemPosition(
        listId: listId,
        itemId: item.id,
        newPosition: adjustedNew,
      );
      // Invalidate list view cache so it picks up new positions
      ref.invalidate(itemsProvider);
    } catch (_) {
      // Revert on failure
      state = AsyncValue.data(items);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load());
  }
}
