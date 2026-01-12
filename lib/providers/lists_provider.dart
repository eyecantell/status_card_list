import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/list_config.dart';
import '../models/item.dart';
import '../models/sort_mode.dart';
import '../repositories/list_config_repository.dart';
import '../utils/constants.dart';
import 'items_provider.dart';

/// Provider for the ListConfigRepository instance
/// Must be overridden in main.dart with the actual repository
final listConfigRepositoryProvider = Provider<ListConfigRepository>((ref) {
  throw UnimplementedError(
    'listConfigRepositoryProvider must be overridden in ProviderScope',
  );
});

/// Provider for all list configs, managed by ListConfigsNotifier
final listConfigsProvider =
    StateNotifierProvider<ListConfigsNotifier, AsyncValue<List<ListConfig>>>(
        (ref) {
  final repository = ref.watch(listConfigRepositoryProvider);
  return ListConfigsNotifier(repository);
});

/// Provider for item lists (which items belong to which list)
final itemListsProvider = StateNotifierProvider<ItemListsNotifier,
    AsyncValue<Map<String, List<String>>>>((ref) {
  final repository = ref.watch(listConfigRepositoryProvider);
  return ItemListsNotifier(repository);
});

/// Provider for current list ID selection
final currentListIdProvider = StateProvider<String>((ref) {
  return DefaultListIds.review;
});

/// Provider for current list config (derived from currentListIdProvider)
final currentListConfigProvider = Provider<ListConfig?>((ref) {
  final currentId = ref.watch(currentListIdProvider);
  final configsAsync = ref.watch(listConfigsProvider);
  return configsAsync.when(
    data: (configs) {
      try {
        return configs.firstWhere((c) => c.uuid == currentId);
      } catch (_) {
        return configs.isNotEmpty ? configs.first : null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for items in the current list (derived, with sorting applied)
final itemsForCurrentListProvider = Provider<List<Item>>((ref) {
  final currentId = ref.watch(currentListIdProvider);
  final currentConfig = ref.watch(currentListConfigProvider);
  final itemListsAsync = ref.watch(itemListsProvider);
  final itemMap = ref.watch(itemMapProvider);
  final itemsNotifier = ref.read(itemsProvider.notifier);

  return itemListsAsync.when(
    data: (itemLists) {
      final itemIds = itemLists[currentId] ?? [];
      var items = itemIds
          .map((id) => itemMap[id])
          .whereType<Item>()
          .toList();

      // Apply sorting
      if (currentConfig != null) {
        items = itemsNotifier.sortItems(items, currentConfig.sortMode);
      }
      return items;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// StateNotifier for managing list configurations
class ListConfigsNotifier extends StateNotifier<AsyncValue<List<ListConfig>>> {
  final ListConfigRepository _repository;

  ListConfigsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final configs = await _repository.getAllConfigs();
      state = AsyncValue.data(configs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Reload configs from repository
  Future<void> refresh() => _load();

  /// Update a single config
  Future<void> updateConfig(ListConfig config) async {
    final configs = state.value ?? [];
    final index = configs.indexWhere((c) => c.uuid == config.uuid);
    if (index >= 0) {
      final updated = [...configs];
      updated[index] = config;
      try {
        await _repository.saveConfigs(updated);
        state = AsyncValue.data(updated);
      } catch (e, stack) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  /// Set sort mode for a specific list
  Future<void> setSortMode(String listId, SortMode mode) async {
    final configs = state.value ?? [];
    final index = configs.indexWhere((c) => c.uuid == listId);
    if (index >= 0) {
      final updated = configs[index].copyWith(sortMode: mode);
      await updateConfig(updated);
    }
  }

  /// Sanitize configs by removing references to deleted lists
  Future<void> sanitizeConfigs(Set<String> validListIds) async {
    final configs = state.value;
    if (configs == null) return;

    var needsUpdate = false;
    final updated = configs.map((config) {
      // Clean swipe actions
      final cleanedSwipeActions = Map<String, String>.from(config.swipeActions);
      cleanedSwipeActions
          .removeWhere((_, targetId) => !validListIds.contains(targetId));

      // Clean buttons
      final cleanedButtons = Map<String, String>.from(config.buttons);
      cleanedButtons
          .removeWhere((_, targetId) => !validListIds.contains(targetId));

      // Clean card icons
      final cleanedCardIcons = config.cardIcons
          .where((entry) => validListIds.contains(entry.targetListId))
          .toList();

      if (cleanedSwipeActions.length != config.swipeActions.length ||
          cleanedButtons.length != config.buttons.length ||
          cleanedCardIcons.length != config.cardIcons.length) {
        needsUpdate = true;
        return config.copyWith(
          swipeActions: cleanedSwipeActions,
          buttons: cleanedButtons,
          cardIcons: cleanedCardIcons,
        );
      }
      return config;
    }).toList();

    if (needsUpdate) {
      await _repository.saveConfigs(updated);
      state = AsyncValue.data(updated);
    }
  }
}

/// StateNotifier for managing item-to-list mappings
class ItemListsNotifier
    extends StateNotifier<AsyncValue<Map<String, List<String>>>> {
  final ListConfigRepository _repository;

  ItemListsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final itemLists = await _repository.getItemLists();
      state = AsyncValue.data(itemLists);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Reload item lists from repository
  Future<void> refresh() => _load();

  /// Move an item from one list to another
  /// Returns the target list name for snackbar notification
  Future<bool> moveItem(
      String itemId, String fromListId, String toListId) async {
    final itemLists = state.value;
    if (itemLists == null) return false;

    try {
      final updated = Map<String, List<String>>.from(
        itemLists.map((k, v) => MapEntry(k, List<String>.from(v))),
      );

      updated[fromListId]?.remove(itemId);
      updated[toListId] ??= [];
      if (!updated[toListId]!.contains(itemId)) {
        updated[toListId]!.add(itemId);
      }

      await _repository.saveItemLists(updated);
      state = AsyncValue.data(updated);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Reorder items within a list
  Future<void> reorderItems(String listId, int oldIndex, int newIndex) async {
    final itemLists = state.value;
    if (itemLists == null) return;

    try {
      final updated = Map<String, List<String>>.from(
        itemLists.map((k, v) => MapEntry(k, List<String>.from(v))),
      );

      final list = updated[listId];
      if (list != null && oldIndex >= 0 && oldIndex < list.length) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        if (newIndex >= 0 && newIndex <= list.length) {
          final item = list.removeAt(oldIndex);
          list.insert(newIndex.clamp(0, list.length), item);

          await _repository.saveItemLists(updated);
          state = AsyncValue.data(updated);
        }
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Sanitize item lists by removing invalid references
  Future<void> sanitize(
      Set<String> validListIds, Set<String> validItemIds) async {
    final itemLists = state.value;
    if (itemLists == null) return;

    var needsUpdate = false;
    final sanitized = <String, List<String>>{};

    for (final listId in validListIds) {
      final items = itemLists[listId] ?? [];
      final cleanedItems =
          items.where((id) => validItemIds.contains(id)).toList();
      sanitized[listId] = cleanedItems;

      if (cleanedItems.length != items.length) {
        needsUpdate = true;
      }
    }

    // Check for lists that were removed
    for (final listId in itemLists.keys) {
      if (!validListIds.contains(listId)) {
        needsUpdate = true;
      }
    }

    if (needsUpdate) {
      await _repository.saveItemLists(sanitized);
      state = AsyncValue.data(sanitized);
    }
  }

  /// Find which list contains a given item
  String? findListContainingItem(String itemId) {
    final itemLists = state.value;
    if (itemLists == null) return null;

    for (final entry in itemLists.entries) {
      if (entry.value.contains(itemId)) {
        return entry.key;
      }
    }
    return null;
  }
}
