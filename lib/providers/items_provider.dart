import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
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
  bool _isRefreshing = false;

  ItemsNotifier(this._dataSource, this._ref) : super(const AsyncValue.loading()) {
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final currentListId = _ref.read(currentListIdProvider);
      final currentConfig = _ref.read(currentListConfigProvider);
      final sortMode = currentConfig?.sortMode ?? 'manual';

      final page = await _dataSource.loadItems(
        listId: currentListId,
        sortMode: sortMode,
      );

      state = AsyncValue.data(page.items);

      // Update the item cache and list index.
      // Preserve detail-enriched items (html loaded) — list items don't carry
      // detail content, so blindly overwriting would discard loaded detail.
      final indexUpdate = <String, String>{};
      _ref.read(itemCacheProvider.notifier).update((cache) {
        final updated = Map<String, Item>.from(cache);
        for (final item in page.items) {
          final existing = updated[item.id];
          if (existing != null && existing.html != null) {
            // Keep the detail-enriched version but update list-level fields
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
          indexUpdate[item.id] = currentListId;
        }
        return updated;
      });
      _ref.read(itemToListIndexProvider.notifier).update((state) =>
        {...state, ...indexUpdate});
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Reload items from data source
  Future<void> refresh() => _loadItems();

  /// Optimistically remove an item from the current list without re-fetching.
  void removeItem(String itemId) {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((item) => item.id != itemId).toList());
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
