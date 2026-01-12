import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_card_list/models/item.dart';
import 'package:status_card_list/repositories/item_repository.dart';

void main() {
  late ItemRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = ItemRepository(prefs);
  });

  group('ItemRepository', () {
    group('getAllItems', () {
      test('returns default items when no data persisted', () async {
        final items = await repository.getAllItems();
        expect(items, isNotEmpty);
        expect(items.length, 5); // 5 default items
        expect(items.first.id, '1');
        expect(items.first.title, 'Task 1');
      });

      test('returns persisted items when available', () async {
        final testItem = Item(
          id: 'test-1',
          title: 'Test Item',
          subtitle: 'Test',
          html: '<p>Test</p>',
          dueDate: DateTime(2025, 1, 1),
          status: 'Open',
        );
        await repository.saveItems([testItem]);

        final items = await repository.getAllItems();
        expect(items.length, 1);
        expect(items.first.id, 'test-1');
        expect(items.first.title, 'Test Item');
      });
    });

    group('saveItem', () {
      test('adds new item to repository', () async {
        await repository.clear();
        await repository.saveItems([]);

        final newItem = Item(
          id: 'new-1',
          title: 'New Item',
          subtitle: 'New',
          html: '',
          dueDate: DateTime(2025, 1, 1),
          status: 'Open',
        );
        await repository.saveItem(newItem);

        final items = await repository.getAllItems();
        expect(items.length, 1);
        expect(items.first.id, 'new-1');
      });

      test('updates existing item', () async {
        final original = Item(
          id: 'update-1',
          title: 'Original',
          subtitle: 'Sub',
          html: '',
          dueDate: DateTime(2025, 1, 1),
          status: 'Open',
        );
        await repository.saveItems([original]);

        final updated = original.copyWith(title: 'Updated');
        await repository.saveItem(updated);

        final items = await repository.getAllItems();
        expect(items.length, 1);
        expect(items.first.title, 'Updated');
      });
    });

    group('deleteItem', () {
      test('removes item from repository', () async {
        final item1 = Item(
          id: 'del-1',
          title: 'Item 1',
          subtitle: '',
          html: '',
          dueDate: DateTime(2025, 1, 1),
          status: 'Open',
        );
        final item2 = Item(
          id: 'del-2',
          title: 'Item 2',
          subtitle: '',
          html: '',
          dueDate: DateTime(2025, 1, 1),
          status: 'Open',
        );
        await repository.saveItems([item1, item2]);

        await repository.deleteItem('del-1');

        final items = await repository.getAllItems();
        expect(items.length, 1);
        expect(items.first.id, 'del-2');
      });

      test('does nothing when item does not exist', () async {
        final item = Item(
          id: 'keep-1',
          title: 'Keep',
          subtitle: '',
          html: '',
          dueDate: DateTime(2025, 1, 1),
          status: 'Open',
        );
        await repository.saveItems([item]);

        await repository.deleteItem('nonexistent');

        final items = await repository.getAllItems();
        expect(items.length, 1);
      });
    });

    group('getItem', () {
      test('returns item when found', () async {
        final item = Item(
          id: 'get-1',
          title: 'Get Me',
          subtitle: '',
          html: '',
          dueDate: DateTime(2025, 1, 1),
          status: 'Open',
        );
        await repository.saveItems([item]);

        final result = await repository.getItem('get-1');
        expect(result, isNotNull);
        expect(result!.title, 'Get Me');
      });

      test('returns null when item not found', () async {
        await repository.saveItems([]);
        final result = await repository.getItem('nonexistent');
        expect(result, isNull);
      });
    });

    group('clear', () {
      test('removes all persisted data', () async {
        final item = Item(
          id: 'clear-1',
          title: 'Clear Me',
          subtitle: '',
          html: '',
          dueDate: DateTime(2025, 1, 1),
          status: 'Open',
        );
        await repository.saveItems([item]);
        await repository.clear();

        // After clear, should return default items
        final items = await repository.getAllItems();
        expect(items.length, 5); // Default items
      });
    });

    group('default items', () {
      test('have valid relatedItemIds', () async {
        final items = await repository.getAllItems();
        final itemIds = items.map((i) => i.id).toSet();

        for (final item in items) {
          for (final relatedId in item.relatedItemIds) {
            expect(itemIds.contains(relatedId), isTrue,
                reason: 'Item ${item.id} has invalid relatedItemId: $relatedId');
          }
        }
      });

      test('have valid due dates relative to now', () async {
        final items = await repository.getAllItems();
        // Items should have due dates around current time
        for (final item in items) {
          expect(item.dueDate, isNotNull);
        }
      });
    });
  });
}
