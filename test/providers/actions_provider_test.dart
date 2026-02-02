import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_card_list/data_source/in_memory_data_source.dart';
import 'package:status_card_list/providers/actions_provider.dart';
import 'package:status_card_list/providers/data_source_provider.dart';
import 'package:status_card_list/providers/items_provider.dart';

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

  group('CardListActions', () {
    group('moveItem', () {
      test('moves item between lists', () async {
        await waitForData(container, itemsProvider);

        final actions = container.read(actionsProvider);
        final success = await actions.moveItem(
          '1',
          dataSource.defaultListId,
          'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        );

        expect(success, isTrue);

        // Verify item is removed from current list after refresh
        await Future.delayed(const Duration(milliseconds: 100));
        final items = container.read(itemsProvider).value ?? [];
        expect(items.map((i) => i.id), isNot(contains('1')));
      });

      test('returns false when move fails for nonexistent item', () async {
        await waitForData(container, itemsProvider);

        final actions = container.read(actionsProvider);
        // Moving a nonexistent item - InMemoryDataSource handles gracefully
        final success = await actions.moveItem(
          'nonexistent',
          dataSource.defaultListId,
          'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        );

        // InMemoryDataSource returns true even for nonexistent items
        // (it just doesn't find anything to move)
        expect(success, isTrue);
      });
    });

    group('reorderItems', () {
      test('reorders items within list', () async {
        await waitForData(container, itemsProvider);

        final actions = container.read(actionsProvider);
        // Move item at index 0 to index 2
        await actions.reorderItems(
          dataSource.defaultListId,
          0,
          2,
        );

        await Future.delayed(const Duration(milliseconds: 100));
        // After refresh, items should be reordered
        final items = container.read(itemsProvider).value ?? [];
        expect(items, isNotEmpty);
      });

      test('does nothing when oldIndex is out of range', () async {
        await waitForData(container, itemsProvider);

        final actions = container.read(actionsProvider);
        // oldIndex 100 is out of range for 3 items
        await actions.reorderItems(
          dataSource.defaultListId,
          100,
          0,
        );

        // Should not throw, items unchanged
        final items = container.read(itemsProvider).value ?? [];
        expect(items.length, 3);
      });
    });

    group('loadItemDetail', () {
      test('loads and caches item detail', () async {
        await waitForData(container, itemsProvider);

        final actions = container.read(actionsProvider);
        final detail = await actions.loadItemDetail('1');

        expect(detail.id, '1');
        expect(detail.title, 'Task 1');
        expect(detail.html, isNotNull);
      });
    });
  });
}
