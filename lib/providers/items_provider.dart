import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/item.dart';
import '../models/list_config.dart';
import '../data_source/card_list_data_source.dart';
import 'data_source_provider.dart';
import 'lists_provider.dart';

/// Provider for all items in the current list, managed by ItemsNotifier
final itemsProvider =
    StateNotifierProvider<ItemsNotifier, AsyncValue<List<Item>>>((ref) {
      final dataSource = ref.watch(dataSourceProvider);
      return ItemsNotifier(dataSource, ref);
    });

/// Current search query. When non-null/non-empty, filters items server-side.
final searchQueryProvider = StateProvider<String?>((ref) => null);

/// Total count of items matching current filters/search (from last API response).
/// Used by bulk-move dialog to show how many notices will be moved.
final itemsTotalCountProvider = StateProvider<int>((ref) => 0);

/// Whether the server has more items beyond the loaded pages.
final itemsHasMoreProvider = StateProvider<bool>((ref) => false);

/// True while a loadMore() fetch is in flight (drives the footer spinner).
final itemsLoadingMoreProvider = StateProvider<bool>((ref) => false);

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
  Future<void>? _inFlightLoad;

  /// Bumped on every fresh load (list switch, sort change, search, refresh).
  /// An in-flight loadMore() compares its captured value after the await and
  /// drops its result if a newer load has started — otherwise it could append
  /// old-query pages onto new-query results.
  int _loadGeneration = 0;

  /// Items appended via injectItem() since the last fresh load. They were
  /// never part of the server's sequential ordering, so loadMore() must not
  /// count them toward the next page offset. Ids are removed again when the
  /// item resurfaces in a real server page (it's then inside the covered
  /// range) or is removed from the list.
  final Set<String> _injectedIds = {};

  ItemsNotifier(this._dataSource, this._ref)
    : super(const AsyncValue.loading()) {
    _inFlightLoad = _doLoad();
  }

  /// Load items for the current list. The actual loading logic.
  Future<void> _doLoad() async {
    _loadGeneration++;
    _injectedIds.clear();
    // Clear a possibly-stuck loading-more flag (e.g. a loadMore() orphaned by
    // a company switch disposing the previous notifier mid-flight).
    _ref.read(itemsLoadingMoreProvider.notifier).state = false;
    try {
      final currentListId = _ref.read(currentListIdProvider);
      if (currentListId.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      // If list configs aren't loaded yet, wait for them before fetching items
      // so we use the stored sort mode rather than falling back to 'manual'.
      // This fixes the race where items load before listConfigsProvider resolves
      // (e.g. on initial render or after a company switch), causing the sort
      // button to show "Best Match" while items are actually in manual order.
      if (!_ref.read(listConfigsProvider).hasValue) {
        final completer = Completer<void>();
        _ref.listen<AsyncValue<List<ListConfig>>>(listConfigsProvider, (_, __) {
          if (!completer.isCompleted) completer.complete();
        });
        // Ensure we don't hang if this notifier is disposed before configs load.
        _ref.onDispose(() {
          if (!completer.isCompleted) completer.complete();
        });
        await completer.future;
      }

      final currentConfig = _ref.read(currentListConfigProvider);
      final sortMode = currentConfig?.sortMode ?? 'manual';

      final searchQuery = _ref.read(searchQueryProvider);

      final page = await _dataSource.loadItems(
        listId: currentListId,
        sortMode: sortMode,
        searchQuery: searchQuery,
      );

      state = AsyncValue.data(page.items);
      _ref.read(itemsTotalCountProvider.notifier).state = page.totalCount;
      _ref.read(itemsHasMoreProvider.notifier).state = page.hasMore;
      _updateCaches(page.items, currentListId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Update the item cache and list index for freshly fetched items.
  /// Preserve detail-enriched items (html loaded) — list items don't carry
  /// detail content, so blindly overwriting would discard loaded detail.
  void _updateCaches(List<Item> items, String listId) {
    final indexUpdate = <String, String>{};
    _ref.read(itemCacheProvider.notifier).update((cache) {
      final updated = Map<String, Item>.from(cache);
      for (final item in items) {
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
        indexUpdate[item.id] = listId;
      }
      return updated;
    });
    _ref
        .read(itemToListIndexProvider.notifier)
        .update((state) => {...state, ...indexUpdate});
  }

  /// Fetch the next page and append it to the current list.
  /// No-op while another load is in flight, when there is nothing more to
  /// load, or when the current state is not data (loading/error).
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!_ref.read(itemsHasMoreProvider)) return;
    if (_ref.read(itemsLoadingMoreProvider)) return;

    _ref.read(itemsLoadingMoreProvider.notifier).state = true;
    final generation = _loadGeneration;
    try {
      final currentListId = _ref.read(currentListIdProvider);
      final sortMode =
          _ref.read(currentListConfigProvider)?.sortMode ?? 'manual';
      final searchQuery = _ref.read(searchQueryProvider);

      final page = await _dataSource.loadItems(
        listId: currentListId,
        sortMode: sortMode,
        searchQuery: searchQuery,
        // Injected items (deep-link navigation) aren't part of the server's
        // ordering — don't let them shift the page offset.
        offset: current.length - _injectedIds.length,
      );

      // Context may have changed while the fetch was in flight: notifier
      // disposed (company switch), a newer load started (refresh, sort or
      // search change), or a different list selected. Drop stale results.
      if (!mounted) return;
      if (generation != _loadGeneration) return;
      if (_ref.read(currentListIdProvider) != currentListId) return;
      final latest = state.valueOrNull;
      if (latest == null) return;

      // An injected item that shows up in a real server page is now inside
      // the covered range — stop counting it as an offset adjustment.
      for (final item in page.items) {
        _injectedIds.remove(item.id);
      }
      final existingIds = latest.map((i) => i.id).toSet();
      final fresh =
          page.items.where((i) => !existingIds.contains(i.id)).toList();
      state = AsyncValue.data([...latest, ...fresh]);
      _ref.read(itemsTotalCountProvider.notifier).state = page.totalCount;
      _ref.read(itemsHasMoreProvider.notifier).state = page.hasMore;
      _updateCaches(fresh, currentListId);
    } catch (_) {
      // Keep what's loaded; the footer button remains for a manual retry.
    } finally {
      // Guard: after disposal, _ref reads throw (and _doLoad's reset above
      // covers clearing the flag for the replacement notifier).
      if (mounted) {
        _ref.read(itemsLoadingMoreProvider.notifier).state = false;
      }
    }
  }

  /// Reload items from data source.
  /// If a load is already in flight, waits for it to finish then starts
  /// a fresh load — this ensures callers always get data for the current
  /// list context (which may have changed during the previous load).
  Future<void> refresh() async {
    if (_inFlightLoad != null) {
      await _inFlightLoad;
    }
    final load = _doLoad();
    _inFlightLoad = load;
    await load;
  }

  /// Whether an item with [itemId] is in the currently loaded items.
  bool containsItem(String itemId) {
    return state.valueOrNull?.any((item) => item.id == itemId) ?? false;
  }

  /// Inject an item into the current list (e.g. for deep-link navigation to
  /// an item beyond the loaded page). Appends to the end if not already present.
  void injectItem(Item item) {
    final current = state.valueOrNull ?? [];
    if (current.any((i) => i.id == item.id)) return;
    _injectedIds.add(item.id);
    state = AsyncValue.data([...current, item]);
  }

  /// Optimistically remove an item from the current list without re-fetching.
  void removeItem(String itemId) {
    final current = state.valueOrNull ?? [];
    _injectedIds.remove(itemId);
    state = AsyncValue.data(
      current.where((item) => item.id != itemId).toList(),
    );
  }

  /// Remove references to deleted items from all items' relatedItemIds
  Future<void> cleanupRelatedItemReferences(Set<String> validItemIds) async {
    final items = state.value;
    if (items == null) return;

    final updated =
        items.map((item) {
          final cleanedRelated =
              item.relatedItemIds
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
