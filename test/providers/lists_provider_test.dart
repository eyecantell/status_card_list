import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_card_list/models/sort_mode.dart';
import 'package:status_card_list/data_source/in_memory_data_source.dart';
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
  });

  group('ListConfigsNotifier', () {
    group('setSortMode', () {
      test('updates sort mode for list', () async {
        await waitForData(container, listConfigsProvider);

        final notifier = container.read(listConfigsProvider.notifier);
        await notifier.setSortMode(dataSource.defaultListId, SortMode.manual);

        await Future.delayed(const Duration(milliseconds: 100));

        final configs = container.read(listConfigsProvider).value;
        final reviewConfig = configs?.firstWhere(
          (c) => c.uuid == dataSource.defaultListId,
        );
        expect(reviewConfig?.sortMode, SortMode.manual);
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
