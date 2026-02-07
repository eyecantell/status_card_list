import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_card_list/models/item.dart';
import 'package:status_card_list/data_source/in_memory_data_source.dart';
import 'package:status_card_list/providers/actions_provider.dart';
import 'package:status_card_list/providers/data_source_provider.dart';
import 'package:status_card_list/providers/items_provider.dart';
import 'package:status_card_list/providers/lists_provider.dart';

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
  late InMemoryDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    dataSource = InMemoryDataSource(prefs);
    await dataSource.initialize();

    container = ProviderContainer(
      overrides: [
        dataSourceProvider.overrideWithValue(dataSource),
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

  group('currentListIdProvider', () {
    test('defaults to DataSource defaultListId', () {
      final currentId = container.read(currentListIdProvider);
      expect(currentId, dataSource.defaultListId);
    });

    test('can be changed', () {
      container.read(currentListIdProvider.notifier).state = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
      final currentId = container.read(currentListIdProvider);
      expect(currentId, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
    });
  });

  group('currentListConfigProvider', () {
    test('returns config for current list', () async {
      await waitForData(container, listConfigsProvider);

      final config = container.read(currentListConfigProvider);
      expect(config, isNotNull);
      expect(config?.uuid, dataSource.defaultListId);
      expect(config?.name, 'Review');
    });

    test('updates when currentListIdProvider changes', () async {
      await waitForData(container, listConfigsProvider);

      container.read(currentListIdProvider.notifier).state = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
      final config = container.read(currentListConfigProvider);
      expect(config?.name, 'Saved');
    });
  });

  group('itemsForCurrentListProvider', () {
    test('returns items for current list', () async {
      await waitForData(container, itemsProvider);

      final items = container.read(itemsForCurrentListProvider);
      expect(items, isNotEmpty);
      // Review list should have items 1, 2, 3
      expect(items.map((i) => i.id), containsAll(['1', '2', '3']));
    });

    test('merges cached HTML into items without HTML', () async {
      await waitForData(container, itemsProvider);

      // Items from list don't have HTML initially (simulating API list response)
      final itemsBefore = container.read(itemsForCurrentListProvider);
      final item1Before = itemsBefore.firstWhere((i) => i.id == '1');

      // Load detail which adds HTML to cache
      final actions = container.read(actionsProvider);
      await actions.loadItemDetail('1');

      // Now itemsForCurrentListProvider should merge the cached HTML
      final itemsAfter = container.read(itemsForCurrentListProvider);
      final item1After = itemsAfter.firstWhere((i) => i.id == '1');

      expect(item1After.html, isNotNull);
      expect(item1After.id, item1Before.id);
      expect(item1After.title, item1Before.title);
    });

    test('keeps item HTML when it already has HTML (does not overwrite with cache)', () async {
      await waitForData(container, itemsProvider);

      // The items from InMemoryDataSource already have HTML
      final itemsBefore = container.read(itemsForCurrentListProvider);
      final item1Before = itemsBefore.firstWhere((i) => i.id == '1');
      expect(item1Before.html, isNotNull);

      // Put different HTML in cache
      const differentHtml = '<p>Different cached HTML</p>';
      final cachedItem = Item(
        id: '1',
        title: 'Task 1',
        subtitle: 'Test',
        status: 'active',
        html: differentHtml,
      );
      container.read(itemCacheProvider.notifier).update((state) {
        final updated = Map<String, Item>.from(state);
        updated['1'] = cachedItem;
        return updated;
      });

      final itemsAfter = container.read(itemsForCurrentListProvider);
      final item1After = itemsAfter.firstWhere((i) => i.id == '1');

      // Item should keep its own HTML (from itemsProvider), not use cached HTML
      // because we only merge cache when item.html == null
      expect(item1After.html, item1Before.html);
      expect(item1After.html, isNot(differentHtml));
    });
  });

  group('ListConfigsNotifier', () {
    group('setSortMode', () {
      test('updates sort mode for list', () async {
        await waitForData(container, listConfigsProvider);

        final notifier = container.read(listConfigsProvider.notifier);
        await notifier.setSortMode(dataSource.defaultListId, 'manual');

        await Future.delayed(const Duration(milliseconds: 100));

        final configs = container.read(listConfigsProvider).value;
        final reviewConfig = configs?.firstWhere(
          (c) => c.uuid == dataSource.defaultListId,
        );
        expect(reviewConfig?.sortMode, 'manual');
      });
    });

    group('updateConfig', () {
      test('updates config properties', () async {
        await waitForData(container, listConfigsProvider);

        final configs = container.read(listConfigsProvider).value;
        final original = configs?.firstWhere(
          (c) => c.uuid == dataSource.defaultListId,
        );
        final updated = original?.copyWith(name: 'Updated Review');

        if (updated != null) {
          final notifier = container.read(listConfigsProvider.notifier);
          await notifier.updateConfig(updated);

          await Future.delayed(const Duration(milliseconds: 100));

          final newConfigs = container.read(listConfigsProvider).value;
          final updatedConfig = newConfigs?.firstWhere(
            (c) => c.uuid == dataSource.defaultListId,
          );
          expect(updatedConfig?.name, 'Updated Review');
        }
      });
    });
  });
}
