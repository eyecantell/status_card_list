import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  group('itemCacheProvider (item map)', () {
    test('provides map of items by ID from cache', () async {
      await waitForData(container, itemsProvider);

      final itemMap = container.read(itemCacheProvider);
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
}
