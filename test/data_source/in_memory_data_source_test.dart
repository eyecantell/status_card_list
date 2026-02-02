import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_card_list/data_source/in_memory_data_source.dart';
import 'package:status_card_list/models/sort_mode.dart';

void main() {
  late InMemoryDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    dataSource = InMemoryDataSource(prefs);
    await dataSource.initialize();
  });

  group('InMemoryDataSource', () {
    group('initialize', () {
      test('loads default items when prefs empty', () async {
        final page = await dataSource.loadItems(
          listId: dataSource.defaultListId,
        );
        expect(page.items, isNotEmpty);
        expect(page.items.length, 3); // Review list has 3 default items
      });

      test('loads default configs when prefs empty', () async {
        final configs = await dataSource.loadLists();
        expect(configs.length, 3); // Review, Saved, Trash
      });
    });

    group('defaultListId', () {
      test('returns the Review list UUID', () {
        expect(dataSource.defaultListId, '550e8400-e29b-41d4-a716-446655440000');
      });
    });

    group('loadItems', () {
      test('returns items for a specific list', () async {
        final page = await dataSource.loadItems(
          listId: dataSource.defaultListId,
        );
        expect(page.items.map((i) => i.id), containsAll(['1', '2', '3']));
        expect(page.totalCount, 3);
        expect(page.hasMore, isFalse);
      });

      test('returns empty for list with no items', () async {
        final page = await dataSource.loadItems(listId: 'nonexistent');
        expect(page.items, isEmpty);
        expect(page.totalCount, 0);
      });

      test('sorts items by dateAscending', () async {
        final page = await dataSource.loadItems(
          listId: dataSource.defaultListId,
          sortMode: SortMode.dateAscending,
        );
        // Items should be sorted by dueDate ascending
        for (int i = 0; i < page.items.length - 1; i++) {
          if (page.items[i].dueDate != null && page.items[i + 1].dueDate != null) {
            expect(
              page.items[i].dueDate!.isBefore(page.items[i + 1].dueDate!) ||
                  page.items[i].dueDate == page.items[i + 1].dueDate,
              isTrue,
            );
          }
        }
      });

      test('sorts items by title', () async {
        final page = await dataSource.loadItems(
          listId: dataSource.defaultListId,
          sortMode: SortMode.title,
        );
        for (int i = 0; i < page.items.length - 1; i++) {
          expect(
            page.items[i].title.compareTo(page.items[i + 1].title) <= 0,
            isTrue,
          );
        }
      });

      test('preserves original order for manual sort', () async {
        final page = await dataSource.loadItems(
          listId: dataSource.defaultListId,
          sortMode: SortMode.manual,
        );
        expect(page.items[0].id, '1');
        expect(page.items[1].id, '2');
        expect(page.items[2].id, '3');
      });
    });

    group('loadItemDetail', () {
      test('returns full item', () async {
        final item = await dataSource.loadItemDetail('1');
        expect(item.id, '1');
        expect(item.title, 'Task 1');
        expect(item.html, isNotNull);
      });

      test('throws for nonexistent item', () async {
        expect(
          () => dataSource.loadItemDetail('nonexistent'),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('moveItem', () {
      test('moves item between lists', () async {
        final success = await dataSource.moveItem(
          itemId: '1',
          fromListId: dataSource.defaultListId,
          targetListId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        );
        expect(success, isTrue);

        // Verify item is in new list
        final savedPage = await dataSource.loadItems(
          listId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        );
        expect(savedPage.items.map((i) => i.id), contains('1'));

        // Verify item is gone from old list
        final reviewPage = await dataSource.loadItems(
          listId: dataSource.defaultListId,
        );
        expect(reviewPage.items.map((i) => i.id), isNot(contains('1')));
      });

      test('does not duplicate item in target list', () async {
        await dataSource.moveItem(
          itemId: '1',
          fromListId: dataSource.defaultListId,
          targetListId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        );
        // Move again
        await dataSource.moveItem(
          itemId: '1',
          fromListId: dataSource.defaultListId,
          targetListId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        );

        final page = await dataSource.loadItems(
          listId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        );
        final count = page.items.where((i) => i.id == '1').length;
        expect(count, 1);
      });
    });

    group('updateItemPosition', () {
      test('reorders items within list', () async {
        // Initial order: 1, 2, 3
        await dataSource.updateItemPosition(
          listId: dataSource.defaultListId,
          itemId: '1',
          newPosition: 2,
        );

        final page = await dataSource.loadItems(
          listId: dataSource.defaultListId,
          sortMode: SortMode.manual,
        );
        // After moving '1' to position 2: should be 2, 3, 1
        expect(page.items[0].id, '2');
        expect(page.items[1].id, '3');
        expect(page.items[2].id, '1');
      });
    });

    group('loadLists', () {
      test('returns all list configs', () async {
        final configs = await dataSource.loadLists();
        expect(configs.length, 3);
        expect(configs.map((c) => c.name), containsAll(['Review', 'Saved', 'Trash']));
      });
    });

    group('updateList', () {
      test('updates list config', () async {
        final configs = await dataSource.loadLists();
        final review = configs.firstWhere((c) => c.name == 'Review');
        final updated = review.copyWith(name: 'Updated Review');

        await dataSource.updateList(review.uuid, updated);

        final newConfigs = await dataSource.loadLists();
        final updatedConfig = newConfigs.firstWhere((c) => c.uuid == review.uuid);
        expect(updatedConfig.name, 'Updated Review');
      });
    });

    group('findListContainingItem', () {
      test('finds correct list for item', () async {
        final listId = await dataSource.findListContainingItem('1');
        expect(listId, dataSource.defaultListId);
      });

      test('returns null for unknown item', () async {
        final listId = await dataSource.findListContainingItem('nonexistent');
        expect(listId, isNull);
      });

      test('finds item in Saved list', () async {
        final listId = await dataSource.findListContainingItem('4');
        expect(listId, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
      });
    });

    group('getStatus', () {
      test('returns counts per list', () async {
        final status = await dataSource.getStatus();
        final counts = status['counts'] as Map<String, int>;
        expect(counts[dataSource.defaultListId], 3);
        expect(counts['a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'], 1);
        expect(counts['c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e'], 1);
      });
    });
  });
}
