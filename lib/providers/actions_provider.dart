import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import 'data_source_provider.dart';
import 'items_provider.dart';

final actionsProvider = Provider<CardListActions>((ref) {
  return CardListActions(ref);
});

class CardListActions {
  final Ref _ref;
  CardListActions(this._ref);

  Future<bool> moveItem(String itemId, String fromListId, String targetListId) async {
    final ds = _ref.read(dataSourceProvider);
    final success = await ds.moveItem(
      itemId: itemId,
      fromListId: fromListId,
      targetListId: targetListId,
    );
    if (success) {
      _ref.read(itemToListIndexProvider.notifier).update((state) =>
        {...state, itemId: targetListId});
      // Stamp movedAt optimistically in the cache
      _ref.read(itemCacheProvider.notifier).update((state) {
        final existing = state[itemId];
        if (existing == null) return state;
        return {...state, itemId: existing.copyWith(movedAt: DateTime.now())};
      });
      _ref.read(itemsProvider.notifier).removeItem(itemId);
      _ref.invalidate(listCountsProvider);
    }
    return success;
  }

  Future<void> reorderItems(String listId, int oldIndex, int newIndex) async {
    final ds = _ref.read(dataSourceProvider);
    final items = _ref.read(itemsProvider).value ?? [];
    if (oldIndex < items.length) {
      final adjustedNew = oldIndex < newIndex ? newIndex - 1 : newIndex;
      await ds.updateItemPosition(
        listId: listId,
        itemId: items[oldIndex].id,
        newPosition: adjustedNew,
      );
      await _ref.read(itemsProvider.notifier).refresh();
    }
  }

  Future<Item> loadItemDetail(String itemId) async {
    // Return cached item if detail (html) is already loaded
    final cached = _ref.read(itemCacheProvider)[itemId];
    if (cached != null && cached.html != null) return cached;

    final ds = _ref.read(dataSourceProvider);
    final detail = await ds.loadItemDetail(itemId);
    _ref.read(itemCacheProvider.notifier).update((state) {
      final updated = Map<String, Item>.from(state);
      updated[itemId] = detail;
      return updated;
    });
    return detail;
  }
}
