import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_card_list/models/item.dart';
import 'package:status_card_list/models/sort_mode.dart';
import 'package:status_card_list/data_source/in_memory_data_source.dart';
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

  group('itemsProvider', () {
    test('loads items on initialization', () async {
      final items = await waitForData(container, itemsProvider);
      expect(items, isNotEmpty);
    });

    test('provides default items when data source is fresh', () async {
      final items = await waitForData(container, itemsProvider);
      // Default Review list has 3 items
      expect(items.length, 3);
    });
  });

  group('itemMapProvider', () {
    test('provides map of items by ID from cache', () async {
      await waitForData(container, itemsProvider);

      final itemMap = container.read(itemMapProvider);
      expect(itemMap, isNotEmpty);
      expect(itemMap['1'], isNotNull);
      expect(itemMap['1']?.title, 'Task 1');
    });
  });

  group('itemCacheProvider', () {
    test('accumulates items from loaded lists', () async {
      await waitForData(container, itemsProvider);

      final cache = container.read(itemCacheProvider);
      // After loading the default Review list, cache should have its items
      expect(cache, isNotEmpty);
      expect(cache.containsKey('1'), isTrue);
    });
  });

  group('itemToListIndexProvider', () {
    test('maps items to their list IDs', () async {
      await waitForData(container, itemsProvider);

      final index = container.read(itemToListIndexProvider);
      expect(index, isNotEmpty);
      expect(index['1'], dataSource.defaultListId);
    });
  });

  group('ItemsNotifier', () {
    group('sortItems', () {
      final items = [
        Item(
          id: '1',
          title: 'C Task',
          subtitle: '',
          html: '',
          dueDate: DateTime(2025, 1, 15),
          status: 'Open',
        ),
        Item(
          id: '2',
          title: 'A Task',
          subtitle: '',
          html: '',
          dueDate: DateTime(2025, 1, 10),
          status: 'Open',
        ),
        Item(
          id: '3',
          title: 'B Task',
          subtitle: '',
          html: '',
          dueDate: DateTime(2025, 1, 20),
          status: 'Open',
        ),
      ];

      test('sorts by dateAscending', () async {
        await waitForData(container, itemsProvider);
        final notifier = container.read(itemsProvider.notifier);

        final sorted = notifier.sortItems(items, SortMode.dateAscending);
        expect(sorted[0].id, '2'); // Jan 10
        expect(sorted[1].id, '1'); // Jan 15
        expect(sorted[2].id, '3'); // Jan 20
      });

      test('sorts by dateDescending', () async {
        await waitForData(container, itemsProvider);
        final notifier = container.read(itemsProvider.notifier);

        final sorted = notifier.sortItems(items, SortMode.dateDescending);
        expect(sorted[0].id, '3'); // Jan 20
        expect(sorted[1].id, '1'); // Jan 15
        expect(sorted[2].id, '2'); // Jan 10
      });

      test('sorts by title', () async {
        await waitForData(container, itemsProvider);
        final notifier = container.read(itemsProvider.notifier);

        final sorted = notifier.sortItems(items, SortMode.title);
        expect(sorted[0].title, 'A Task');
        expect(sorted[1].title, 'B Task');
        expect(sorted[2].title, 'C Task');
      });

      test('returns original order for manual', () async {
        await waitForData(container, itemsProvider);
        final notifier = container.read(itemsProvider.notifier);

        final sorted = notifier.sortItems(items, SortMode.manual);
        expect(sorted[0].id, '1');
        expect(sorted[1].id, '2');
        expect(sorted[2].id, '3');
      });

      test('does not modify original list', () async {
        await waitForData(container, itemsProvider);
        final notifier = container.read(itemsProvider.notifier);
        final original = [...items];

        notifier.sortItems(items, SortMode.title);

        expect(items[0].id, original[0].id);
        expect(items[1].id, original[1].id);
        expect(items[2].id, original[2].id);
      });

      test('sorts by deadlineSoonest (same as dateAscending)', () async {
        await waitForData(container, itemsProvider);
        final notifier = container.read(itemsProvider.notifier);

        final sorted = notifier.sortItems(items, SortMode.deadlineSoonest);
        expect(sorted[0].id, '2');
        expect(sorted[2].id, '3');
      });

      test('sorts by newest (same as dateDescending)', () async {
        await waitForData(container, itemsProvider);
        final notifier = container.read(itemsProvider.notifier);

        final sorted = notifier.sortItems(items, SortMode.newest);
        expect(sorted[0].id, '3');
        expect(sorted[2].id, '2');
      });

      test('sorts by similarityDescending using extra field', () async {
        await waitForData(container, itemsProvider);
        final notifier = container.read(itemsProvider.notifier);

        final similarityItems = [
          Item(id: '1', title: 'Low', subtitle: '', status: 'Open',
              extra: {'best_similarity': 0.3}),
          Item(id: '2', title: 'High', subtitle: '', status: 'Open',
              extra: {'best_similarity': 0.9}),
          Item(id: '3', title: 'Mid', subtitle: '', status: 'Open',
              extra: {'best_similarity': 0.6}),
        ];

        final sorted = notifier.sortItems(similarityItems, SortMode.similarityDescending);
        expect(sorted[0].id, '2'); // 0.9
        expect(sorted[1].id, '3'); // 0.6
        expect(sorted[2].id, '1'); // 0.3
      });

      test('handles null dueDates in sorting (nulls last)', () async {
        await waitForData(container, itemsProvider);
        final notifier = container.read(itemsProvider.notifier);

        final mixedItems = [
          Item(id: '1', title: 'No date', subtitle: '', status: 'Open'),
          Item(id: '2', title: 'Has date', subtitle: '', status: 'Open',
              dueDate: DateTime(2025, 1, 10)),
          Item(id: '3', title: 'Also no date', subtitle: '', status: 'Open'),
        ];

        final sorted = notifier.sortItems(mixedItems, SortMode.dateAscending);
        expect(sorted[0].id, '2'); // Has date comes first
        expect(sorted[1].dueDate, isNull); // Nulls last
        expect(sorted[2].dueDate, isNull);
      });
    });
  });
}
