import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../models/sort_mode.dart';
import '../repositories/item_repository.dart';

/// Provider for the ItemRepository instance
/// Must be overridden in main.dart with the actual repository
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  throw UnimplementedError(
    'itemRepositoryProvider must be overridden in ProviderScope',
  );
});

/// Provider for all items, managed by ItemsNotifier
final itemsProvider =
    StateNotifierProvider<ItemsNotifier, AsyncValue<List<Item>>>((ref) {
  final repository = ref.watch(itemRepositoryProvider);
  return ItemsNotifier(repository);
});

/// Provider for item map (O(1) lookup by ID)
final itemMapProvider = Provider<Map<String, Item>>((ref) {
  final itemsAsync = ref.watch(itemsProvider);
  return itemsAsync.when(
    data: (items) => {for (var item in items) item.id: item},
    loading: () => {},
    error: (_, __) => {},
  );
});

/// StateNotifier for managing items state
class ItemsNotifier extends StateNotifier<AsyncValue<List<Item>>> {
  final ItemRepository _repository;

  ItemsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadItems();
  }

  Future<void> _loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getAllItems();
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Reload items from repository
  Future<void> refresh() => _loadItems();

  /// Add a new item
  Future<void> addItem(Item item) async {
    try {
      await _repository.saveItem(item);
      await _loadItems();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update an existing item
  Future<void> updateItem(Item item) async {
    try {
      await _repository.saveItem(item);
      await _loadItems();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Delete an item by ID
  Future<void> deleteItem(String id) async {
    try {
      await _repository.deleteItem(id);
      await _loadItems();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Sort items according to the specified mode
  List<Item> sortItems(List<Item> items, SortMode mode) {
    if (mode == SortMode.manual) return items;

    final sorted = [...items];
    switch (mode) {
      case SortMode.dateAscending:
        sorted.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      case SortMode.dateDescending:
        sorted.sort((a, b) => b.dueDate.compareTo(a.dueDate));
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

    var needsUpdate = false;
    final updated = items.map((item) {
      final cleanedRelated = item.relatedItemIds
          .where((id) => validItemIds.contains(id))
          .toList();
      if (cleanedRelated.length != item.relatedItemIds.length) {
        needsUpdate = true;
        return item.copyWith(relatedItemIds: cleanedRelated);
      }
      return item;
    }).toList();

    if (needsUpdate) {
      await _repository.saveItems(updated);
      state = AsyncValue.data(updated);
    }
  }
}
