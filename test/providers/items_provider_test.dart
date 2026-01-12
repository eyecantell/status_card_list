import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_card_list/models/item.dart';
import 'package:status_card_list/models/sort_mode.dart';
import 'package:status_card_list/providers/items_provider.dart';
import 'package:status_card_list/repositories/item_repository.dart';

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
  late ItemRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = ItemRepository(prefs);

    container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWithValue(repository),
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

    test('provides default items when repository is empty', () async {
      final items = await waitForData(container, itemsProvider);
      expect(items.length, 5); // Default items
    });
  });

  group('itemMapProvider', () {
    test('provides map of items by ID', () async {
      await waitForData(container, itemsProvider);

      final itemMap = container.read(itemMapProvider);
      expect(itemMap, isNotEmpty);
      expect(itemMap['1'], isNotNull);
      expect(itemMap['1']?.title, 'Task 1');
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
    });

    group('CRUD operations', () {
      test('addItem adds new item', () async {
        // Clear and setup fresh repository
        await repository.clear();
        await repository.saveItems([]);

        final notifier = container.read(itemsProvider.notifier);
        await notifier.refresh();
        await waitForData(container, itemsProvider);

        final newItem = Item(
          id: 'new-1',
          title: 'New Task',
          subtitle: '',
          html: '',
          dueDate: DateTime.now(),
          status: 'Open',
        );

        await notifier.addItem(newItem);
        await waitForData(container, itemsProvider);

        final items = container.read(itemsProvider).value;
        expect(items?.any((i) => i.id == 'new-1'), isTrue);
      });

      test('updateItem updates existing item', () async {
        await repository.clear();
        final original = Item(
          id: 'update-1',
          title: 'Original',
          subtitle: '',
          html: '',
          dueDate: DateTime.now(),
          status: 'Open',
        );
        await repository.saveItems([original]);

        final notifier = container.read(itemsProvider.notifier);
        await notifier.refresh();
        await waitForData(container, itemsProvider);

        final updated = original.copyWith(title: 'Updated');
        await notifier.updateItem(updated);
        await waitForData(container, itemsProvider);

        final items = container.read(itemsProvider).value;
        final item = items?.firstWhere((i) => i.id == 'update-1');
        expect(item?.title, 'Updated');
      });

      test('deleteItem removes item', () async {
        await repository.clear();
        final item = Item(
          id: 'delete-1',
          title: 'Delete Me',
          subtitle: '',
          html: '',
          dueDate: DateTime.now(),
          status: 'Open',
        );
        await repository.saveItems([item]);

        final notifier = container.read(itemsProvider.notifier);
        await notifier.refresh();
        await waitForData(container, itemsProvider);

        await notifier.deleteItem('delete-1');
        await waitForData(container, itemsProvider);

        final items = container.read(itemsProvider).value;
        expect(items?.any((i) => i.id == 'delete-1'), isFalse);
      });
    });
  });
}
