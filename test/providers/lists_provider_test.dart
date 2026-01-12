import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_card_list/models/sort_mode.dart';
import 'package:status_card_list/providers/items_provider.dart';
import 'package:status_card_list/providers/lists_provider.dart';
import 'package:status_card_list/repositories/item_repository.dart';
import 'package:status_card_list/repositories/list_config_repository.dart';
import 'package:status_card_list/utils/constants.dart';

/// Helper to wait for provider to have data
Future<T> waitForData<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final startTime = DateTime.now();
  while (DateTime.now().difference(startTime) < timeout) {
    final state = container.read(provider);
    if (state.hasValue) {
      return state.value as T;
    }
    await Future.delayed(const Duration(milliseconds: 50));
  }
  throw TimeoutException('Waiting for provider data timed out');
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

void main() {
  late ProviderContainer container;
  late ListConfigRepository listConfigRepository;
  late ItemRepository itemRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    listConfigRepository = ListConfigRepository(prefs);
    itemRepository = ItemRepository(prefs);

    container = ProviderContainer(
      overrides: [
        listConfigRepositoryProvider.overrideWithValue(listConfigRepository),
        itemRepositoryProvider.overrideWithValue(itemRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('listConfigsProvider', () {
    test('loads configs on initialization', () async {
      final configs = await waitForData(container, listConfigsProvider);
      expect(configs, isNotEmpty);
    });

    test('provides default configs', () async {
      final configs = await waitForData(container, listConfigsProvider);
      expect(configs.length, 3); // Review, Saved, Trash
    });
  });

  group('itemListsProvider', () {
    test('loads item lists on initialization', () async {
      final itemLists = await waitForData(container, itemListsProvider);
      expect(itemLists, isNotEmpty);
    });

    test('provides default item lists', () async {
      final itemLists = await waitForData(container, itemListsProvider);
      expect(itemLists[DefaultListIds.review], contains('1'));
      expect(itemLists[DefaultListIds.saved], contains('4'));
      expect(itemLists[DefaultListIds.trash], contains('5'));
    });
  });

  group('currentListIdProvider', () {
    test('defaults to Review list', () {
      final currentId = container.read(currentListIdProvider);
      expect(currentId, DefaultListIds.review);
    });

    test('can be changed', () {
      container.read(currentListIdProvider.notifier).state = DefaultListIds.saved;
      final currentId = container.read(currentListIdProvider);
      expect(currentId, DefaultListIds.saved);
    });
  });

  group('currentListConfigProvider', () {
    test('returns config for current list', () async {
      await waitForData(container, listConfigsProvider);

      final config = container.read(currentListConfigProvider);
      expect(config, isNotNull);
      expect(config?.uuid, DefaultListIds.review);
      expect(config?.name, 'Review');
    });

    test('updates when currentListIdProvider changes', () async {
      await waitForData(container, listConfigsProvider);

      container.read(currentListIdProvider.notifier).state = DefaultListIds.saved;
      final config = container.read(currentListConfigProvider);
      expect(config?.name, 'Saved');
    });
  });

  group('itemsForCurrentListProvider', () {
    test('returns items for current list', () async {
      await waitForData(container, itemsProvider);
      await waitForData(container, itemListsProvider);

      final items = container.read(itemsForCurrentListProvider);
      expect(items, isNotEmpty);
      // Review list should have items 1, 2, 3
      expect(items.map((i) => i.id), containsAll(['1', '2', '3']));
    });

    test('updates when list changes', () async {
      await waitForData(container, itemsProvider);
      await waitForData(container, itemListsProvider);

      container.read(currentListIdProvider.notifier).state = DefaultListIds.saved;

      final items = container.read(itemsForCurrentListProvider);
      expect(items.map((i) => i.id), contains('4'));
    });
  });

  group('ItemListsNotifier', () {
    group('moveItem', () {
      test('moves item between lists', () async {
        await waitForData(container, itemListsProvider);

        final notifier = container.read(itemListsProvider.notifier);
        final success = await notifier.moveItem(
          '1',
          DefaultListIds.review,
          DefaultListIds.saved,
        );

        expect(success, isTrue);

        final itemLists = container.read(itemListsProvider).value;
        expect(itemLists?[DefaultListIds.review], isNot(contains('1')));
        expect(itemLists?[DefaultListIds.saved], contains('1'));
      });

      test('does not duplicate item if already in target', () async {
        await waitForData(container, itemListsProvider);

        final notifier = container.read(itemListsProvider.notifier);
        // Move item 1 to Saved
        await notifier.moveItem('1', DefaultListIds.review, DefaultListIds.saved);
        // Try to move again
        await notifier.moveItem('1', DefaultListIds.review, DefaultListIds.saved);

        final itemLists = container.read(itemListsProvider).value;
        final savedItems = itemLists?[DefaultListIds.saved] ?? [];
        expect(savedItems.where((id) => id == '1').length, 1);
      });
    });

    group('reorderItems', () {
      test('reorders items within list', () async {
        await waitForData(container, itemListsProvider);

        final notifier = container.read(itemListsProvider.notifier);
        // Initial order: ['1', '2', '3']
        // Moving index 0 to index 2 means: item '1' moves after '2'
        // newIndex is adjusted: oldIndex=0, newIndex=2 -> newIndex becomes 1
        // Result: ['2', '1', '3']
        await notifier.reorderItems(DefaultListIds.review, 0, 2);

        final itemLists = container.read(itemListsProvider).value;
        final reviewItems = itemLists?[DefaultListIds.review];
        expect(reviewItems?[0], '2');
        expect(reviewItems?[1], '1');
        expect(reviewItems?[2], '3');
      });
    });

    group('findListContainingItem', () {
      test('finds correct list for item', () async {
        await waitForData(container, itemListsProvider);

        final notifier = container.read(itemListsProvider.notifier);
        final listId = notifier.findListContainingItem('1');
        expect(listId, DefaultListIds.review);
      });

      test('returns null for unknown item', () async {
        await waitForData(container, itemListsProvider);

        final notifier = container.read(itemListsProvider.notifier);
        final listId = notifier.findListContainingItem('nonexistent');
        expect(listId, isNull);
      });
    });
  });

  group('ListConfigsNotifier', () {
    group('setSortMode', () {
      test('updates sort mode for list', () async {
        await waitForData(container, listConfigsProvider);

        final notifier = container.read(listConfigsProvider.notifier);
        await notifier.setSortMode(DefaultListIds.review, SortMode.manual);

        // Wait for state update
        await Future.delayed(const Duration(milliseconds: 100));

        final configs = container.read(listConfigsProvider).value;
        final reviewConfig = configs?.firstWhere(
          (c) => c.uuid == DefaultListIds.review,
        );
        expect(reviewConfig?.sortMode, SortMode.manual);
      });
    });

    group('updateConfig', () {
      test('updates config properties', () async {
        await waitForData(container, listConfigsProvider);

        final configs = container.read(listConfigsProvider).value;
        final original = configs?.firstWhere(
          (c) => c.uuid == DefaultListIds.review,
        );
        final updated = original?.copyWith(name: 'Updated Review');

        if (updated != null) {
          final notifier = container.read(listConfigsProvider.notifier);
          await notifier.updateConfig(updated);

          // Wait for state update
          await Future.delayed(const Duration(milliseconds: 100));

          final newConfigs = container.read(listConfigsProvider).value;
          final updatedConfig = newConfigs?.firstWhere(
            (c) => c.uuid == DefaultListIds.review,
          );
          expect(updatedConfig?.name, 'Updated Review');
        }
      });
    });
  });
}
