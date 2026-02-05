import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../models/sort_mode.dart';
import '../data_source/card_list_data_source.dart';
import 'data_source_provider.dart';
import 'lists_provider.dart';

/// Provider for all items in the current list, managed by ItemsNotifier
final itemsProvider =
    StateNotifierProvider<ItemsNotifier, AsyncValue<List<Item>>>((ref) {
  final dataSource = ref.watch(dataSourceProvider);
  return ItemsNotifier(dataSource, ref);
});

/// Accumulated cache of all items seen across lists.
/// Used for cross-list lookups (related items, detail).
final itemCacheProvider = StateProvider<Map<String, Item>>((ref) => {});

/// Item-to-list index. Maps item ID → list ID.
/// Used synchronously by StatusCard for related item list lookup.
final itemToListIndexProvider = StateProvider<Map<String, String>>((ref) => {});

/// Provider for item map (O(1) lookup by ID) - derived from item cache
final itemMapProvider = Provider<Map<String, Item>>((ref) {
  return ref.watch(itemCacheProvider);
});

/// Provider for item counts per list, fetched via getStatus().
/// Lightweight alternative to loading all items just for counts.
final listCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final dataSource = ref.watch(dataSourceProvider);
  final status = await dataSource.getStatus();
  final counts = status['counts'] as Map<String, dynamic>? ?? {};
  return counts.map((key, value) => MapEntry(key, value as int));
});

/// StateNotifier for managing items state
class ItemsNotifier extends StateNotifier<AsyncValue<List<Item>>> {
  final CardListDataSource _dataSource;
  final Ref _ref;

  ItemsNotifier(this._dataSource, this._ref) : super(const AsyncValue.loading()) {
    _loadItems();
  }

  Future<void> _loadItems() async {
    state = const AsyncValue.loading();
    try {
      final currentListId = _ref.read(currentListIdProvider);
      final currentConfig = _ref.read(currentListConfigProvider);
      final sortMode = currentConfig?.sortMode ?? SortMode.dateAscending;

      final page = await _dataSource.loadItems(
        listId: currentListId,
        sortMode: sortMode,
      );

      state = AsyncValue.data(page.items);

      // Update the item cache and list index
      final cacheUpdate = <String, Item>{};
      final indexUpdate = <String, String>{};
      for (final item in page.items) {
        cacheUpdate[item.id] = item;
        indexUpdate[item.id] = currentListId;
      }
      _ref.read(itemCacheProvider.notifier).update((state) =>
        {...state, ...cacheUpdate});
      _ref.read(itemToListIndexProvider.notifier).update((state) =>
        {...state, ...indexUpdate});
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Reload items from data source
  Future<void> refresh() => _loadItems();

  /// Optimistically remove an item from the current list without re-fetching.
  void removeItem(String itemId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((item) => item.id != itemId).toList());
  }

  /// Sort items according to the specified mode (utility for consumers)
  List<Item> sortItems(List<Item> items, SortMode mode) {
    if (mode == SortMode.manual) return items;

    final sorted = [...items];
    switch (mode) {
      case SortMode.dateAscending:
      case SortMode.deadlineSoonest:
        sorted.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      case SortMode.dateDescending:
      case SortMode.newest:
        sorted.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return b.dueDate!.compareTo(a.dueDate!);
        });
      case SortMode.similarityDescending:
        sorted.sort((a, b) {
          final aScore = (a.extra['best_similarity'] as num?) ?? 0;
          final bScore = (b.extra['best_similarity'] as num?) ?? 0;
          return bScore.compareTo(aScore);
        });
      case SortMode.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
      case SortMode.manual:
        break;
    }
    return sorted;
  }

  /// Remove references to deleted items from all items' relatedItemIds
  Future<void> cleanupRelatedItemReferences(Set<String> validItemIds) async {
    final items = state.value;
    if (items == null) return;

    final updated = items.map((item) {
      final cleanedRelated = item.relatedItemIds
          .where((id) => validItemIds.contains(id))
          .toList();
      if (cleanedRelated.length != item.relatedItemIds.length) {
        return item.copyWith(relatedItemIds: cleanedRelated);
      }
      return item;
    }).toList();

    state = AsyncValue.data(updated);
  }
}
