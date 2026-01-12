import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_card_list/models/list_config.dart';
import 'package:status_card_list/models/sort_mode.dart';
import 'package:status_card_list/repositories/list_config_repository.dart';
import 'package:status_card_list/utils/constants.dart';

void main() {
  late ListConfigRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = ListConfigRepository(prefs);
  });

  group('ListConfigRepository', () {
    group('getAllConfigs', () {
      test('returns default configs when no data persisted', () async {
        final configs = await repository.getAllConfigs();
        expect(configs.length, 3); // Review, Saved, Trash
        expect(configs.map((c) => c.name), containsAll(['Review', 'Saved', 'Trash']));
      });

      test('returns persisted configs when available', () async {
        final testConfig = ListConfig(
          uuid: 'test-uuid',
          name: 'Test List',
          swipeActions: {},
          buttons: {},
        );
        await repository.saveConfigs([testConfig]);

        final configs = await repository.getAllConfigs();
        expect(configs.length, 1);
        expect(configs.first.name, 'Test List');
      });
    });

    group('saveConfig', () {
      test('adds new config', () async {
        await repository.clear();
        await repository.saveConfigs([]);

        final newConfig = ListConfig(
          uuid: 'new-uuid',
          name: 'New List',
          swipeActions: {},
          buttons: {},
        );
        await repository.saveConfig(newConfig);

        final configs = await repository.getAllConfigs();
        expect(configs.length, 1);
        expect(configs.first.name, 'New List');
      });

      test('updates existing config', () async {
        final original = ListConfig(
          uuid: 'update-uuid',
          name: 'Original',
          swipeActions: {},
          buttons: {},
        );
        await repository.saveConfigs([original]);

        final updated = original.copyWith(name: 'Updated');
        await repository.saveConfig(updated);

        final configs = await repository.getAllConfigs();
        expect(configs.length, 1);
        expect(configs.first.name, 'Updated');
      });
    });

    group('getConfig', () {
      test('returns config when found', () async {
        final config = ListConfig(
          uuid: 'find-uuid',
          name: 'Find Me',
          swipeActions: {},
          buttons: {},
        );
        await repository.saveConfigs([config]);

        final result = await repository.getConfig('find-uuid');
        expect(result, isNotNull);
        expect(result!.name, 'Find Me');
      });

      test('returns null when config not found', () async {
        await repository.saveConfigs([]);
        final result = await repository.getConfig('nonexistent');
        expect(result, isNull);
      });
    });

    group('getItemLists', () {
      test('returns default item lists when no data persisted', () async {
        final itemLists = await repository.getItemLists();
        expect(itemLists.length, 3);
        expect(itemLists[DefaultListIds.review], containsAll(['1', '2', '3']));
        expect(itemLists[DefaultListIds.saved], contains('4'));
        expect(itemLists[DefaultListIds.trash], contains('5'));
      });

      test('returns persisted item lists when available', () async {
        final testLists = {
          'list-1': ['item-a', 'item-b'],
          'list-2': ['item-c'],
        };
        await repository.saveItemLists(testLists);

        final itemLists = await repository.getItemLists();
        expect(itemLists.length, 2);
        expect(itemLists['list-1'], ['item-a', 'item-b']);
        expect(itemLists['list-2'], ['item-c']);
      });
    });

    group('saveItemLists', () {
      test('persists item lists', () async {
        final testLists = {
          'list-x': ['item-1', 'item-2'],
        };
        await repository.saveItemLists(testLists);

        final retrieved = await repository.getItemLists();
        expect(retrieved['list-x'], ['item-1', 'item-2']);
      });

      test('overwrites previous item lists', () async {
        await repository.saveItemLists({'old': ['a']});
        await repository.saveItemLists({'new': ['b']});

        final retrieved = await repository.getItemLists();
        expect(retrieved.containsKey('old'), isFalse);
        expect(retrieved['new'], ['b']);
      });
    });

    group('clear', () {
      test('removes all persisted data', () async {
        final config = ListConfig(
          uuid: 'clear-uuid',
          name: 'Clear Me',
          swipeActions: {},
          buttons: {},
        );
        await repository.saveConfigs([config]);
        await repository.saveItemLists({'list': ['item']});

        await repository.clear();

        // After clear, should return defaults
        final configs = await repository.getAllConfigs();
        expect(configs.length, 3); // Default configs

        final itemLists = await repository.getItemLists();
        expect(itemLists.length, 3); // Default item lists
      });
    });

    group('default configs', () {
      test('have valid UUIDs', () async {
        final configs = await repository.getAllConfigs();
        for (final config in configs) {
          expect(config.uuid, isNotEmpty);
        }
      });

      test('have valid swipe actions pointing to other lists', () async {
        final configs = await repository.getAllConfigs();
        final uuids = configs.map((c) => c.uuid).toSet();

        for (final config in configs) {
          for (final targetId in config.swipeActions.values) {
            expect(uuids.contains(targetId), isTrue,
                reason: 'Config ${config.name} has invalid swipe target: $targetId');
          }
        }
      });

      test('have valid button actions pointing to other lists', () async {
        final configs = await repository.getAllConfigs();
        final uuids = configs.map((c) => c.uuid).toSet();

        for (final config in configs) {
          for (final targetId in config.buttons.values) {
            expect(uuids.contains(targetId), isTrue,
                reason: 'Config ${config.name} has invalid button target: $targetId');
          }
        }
      });

      test('have valid cardIcons pointing to other lists', () async {
        final configs = await repository.getAllConfigs();
        final uuids = configs.map((c) => c.uuid).toSet();

        for (final config in configs) {
          for (final cardIcon in config.cardIcons) {
            expect(uuids.contains(cardIcon.targetListId), isTrue,
                reason: 'Config ${config.name} has invalid cardIcon target: ${cardIcon.targetListId}');
          }
        }
      });

      test('have default sortMode of dateAscending', () async {
        final configs = await repository.getAllConfigs();
        for (final config in configs) {
          expect(config.sortMode, SortMode.dateAscending);
        }
      });
    });

    group('default item lists', () {
      test('reference valid list UUIDs', () async {
        final configs = await repository.getAllConfigs();
        final itemLists = await repository.getItemLists();
        final validUuids = configs.map((c) => c.uuid).toSet();

        for (final listId in itemLists.keys) {
          expect(validUuids.contains(listId), isTrue,
              reason: 'Item list references invalid UUID: $listId');
        }
      });

      test('contain expected item IDs', () async {
        final itemLists = await repository.getItemLists();
        final allItemIds = itemLists.values.expand((ids) => ids).toSet();
        expect(allItemIds, containsAll(['1', '2', '3', '4', '5']));
      });
    });
  });
}
