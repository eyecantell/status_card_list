import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/list_config.dart';
import '../models/item.dart';
import '../models/sort_mode.dart';
import '../data_source/card_list_data_source.dart';
import 'data_source_provider.dart';
import 'items_provider.dart';

/// Provider for all list configs, managed by ListConfigsNotifier
final listConfigsProvider =
    StateNotifierProvider<ListConfigsNotifier, AsyncValue<List<ListConfig>>>(
        (ref) {
  final dataSource = ref.watch(dataSourceProvider);
  return ListConfigsNotifier(dataSource);
});

/// Provider for current list ID selection
final currentListIdProvider = StateProvider<String>((ref) {
  final ds = ref.read(dataSourceProvider);
  return ds.defaultListId;
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

/// Provider for items in the current list (merges with cache for HTML)
final itemsForCurrentListProvider = Provider<List<Item>>((ref) {
  final cache = ref.watch(itemCacheProvider);
  return ref.watch(itemsProvider).when(
    data: (items) => items.map((item) {
      final cached = cache[item.id];
      // Preserve HTML from cache if the current item doesn't have it
      if (cached?.html != null && item.html == null) {
        return item.copyWith(html: cached!.html);
      }
      return item;
    }).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// StateNotifier for managing list configurations
class ListConfigsNotifier extends StateNotifier<AsyncValue<List<ListConfig>>> {
  final CardListDataSource _dataSource;

  ListConfigsNotifier(this._dataSource) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final configs = await _dataSource.loadLists();
      state = AsyncValue.data(configs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Reload configs from data source
  Future<void> refresh() => _load();

  /// Update a single config
  Future<void> updateConfig(ListConfig config) async {
    final configs = state.value ?? [];
    final index = configs.indexWhere((c) => c.uuid == config.uuid);
    if (index >= 0) {
      try {
        await _dataSource.updateList(config.uuid, config);
        final updated = [...configs];
        updated[index] = config;
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
      final cleanedSwipeActions = Map<String, String>.from(config.swipeActions);
      cleanedSwipeActions
          .removeWhere((_, targetId) => !validListIds.contains(targetId));

      final cleanedButtons = Map<String, String>.from(config.buttons);
      cleanedButtons
          .removeWhere((_, targetId) => !validListIds.contains(targetId));

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
      for (final config in updated) {
        await _dataSource.updateList(config.uuid, config);
      }
      state = AsyncValue.data(updated);
    }
  }
}
