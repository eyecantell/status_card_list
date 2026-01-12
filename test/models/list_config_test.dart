import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:status_card_list/models/list_config.dart';
import 'package:status_card_list/models/sort_mode.dart';

void main() {
  group('ListConfig', () {
    late ListConfig testConfig;

    setUp(() {
      testConfig = ListConfig(
        uuid: '550e8400-e29b-41d4-a716-446655440000',
        name: 'Review',
        swipeActions: {
          'right': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          'left': 'c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e',
        },
        buttons: {
          'check_circle': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          'delete': 'c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e',
        },
        iconName: 'rate_review',
        colorValue: 0xFF2196F3,
        cardIcons: [
          CardIconEntry(
            iconName: 'check_circle',
            targetListId: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
          ),
          CardIconEntry(
            iconName: 'delete',
            targetListId: 'c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e',
          ),
        ],
      );
    });

    group('icon getter', () {
      test('returns correct IconData for known icon name', () {
        expect(testConfig.icon, Icons.rate_review);
      });

      test('returns Icons.list for unknown icon name', () {
        final config = testConfig.copyWith(iconName: 'unknown_icon');
        expect(config.icon, Icons.list);
      });

      test('returns Icons.bookmark for bookmark icon', () {
        final config = testConfig.copyWith(iconName: 'bookmark');
        expect(config.icon, Icons.bookmark);
      });
    });

    group('color getter', () {
      test('returns correct Color from colorValue', () {
        expect(testConfig.color, const Color(0xFF2196F3));
      });

      test('returns green Color for green value', () {
        final config = testConfig.copyWith(colorValue: 0xFF4CAF50);
        expect(config.color, const Color(0xFF4CAF50));
      });
    });

    group('defaults', () {
      test('dueDateLabel defaults to "Due Date"', () {
        final config = ListConfig(
          uuid: 'test',
          name: 'Test',
          swipeActions: {},
          buttons: {},
        );
        expect(config.dueDateLabel, 'Due Date');
      });

      test('sortMode defaults to dateAscending', () {
        final config = ListConfig(
          uuid: 'test',
          name: 'Test',
          swipeActions: {},
          buttons: {},
        );
        expect(config.sortMode, SortMode.dateAscending);
      });

      test('iconName defaults to "list"', () {
        final config = ListConfig(
          uuid: 'test',
          name: 'Test',
          swipeActions: {},
          buttons: {},
        );
        expect(config.iconName, 'list');
        expect(config.icon, Icons.list);
      });

      test('colorValue defaults to blue', () {
        final config = ListConfig(
          uuid: 'test',
          name: 'Test',
          swipeActions: {},
          buttons: {},
        );
        expect(config.colorValue, 0xFF2196F3);
      });

      test('cardIcons defaults to empty list', () {
        final config = ListConfig(
          uuid: 'test',
          name: 'Test',
          swipeActions: {},
          buttons: {},
        );
        expect(config.cardIcons, isEmpty);
      });
    });

    group('JSON serialization', () {
      test('toJson creates valid JSON map', () {
        final json = testConfig.toJson();
        expect(json['uuid'], '550e8400-e29b-41d4-a716-446655440000');
        expect(json['name'], 'Review');
        expect(json['swipeActions'], isA<Map>());
        expect(json['buttons'], isA<Map>());
        expect(json['iconName'], 'rate_review');
        expect(json['colorValue'], 0xFF2196F3);
        expect(json['cardIcons'], isA<List>());
      });

      test('fromJson creates ListConfig from JSON map', () {
        final json = testConfig.toJson();
        final recreated = ListConfig.fromJson(json);
        expect(recreated.uuid, testConfig.uuid);
        expect(recreated.name, testConfig.name);
        expect(recreated.swipeActions, testConfig.swipeActions);
        expect(recreated.iconName, testConfig.iconName);
        expect(recreated.colorValue, testConfig.colorValue);
      });
    });

    group('copyWith', () {
      test('creates copy with modified name', () {
        final copy = testConfig.copyWith(name: 'New Name');
        expect(copy.name, 'New Name');
        expect(copy.uuid, testConfig.uuid);
      });

      test('creates copy with modified sortMode', () {
        final copy = testConfig.copyWith(sortMode: SortMode.manual);
        expect(copy.sortMode, SortMode.manual);
      });
    });
  });

  group('CardIconEntry', () {
    test('creates entry with required fields', () {
      final entry = CardIconEntry(
        iconName: 'check_circle',
        targetListId: 'test-uuid',
      );
      expect(entry.iconName, 'check_circle');
      expect(entry.targetListId, 'test-uuid');
    });

    test('toJson and fromJson round-trip', () {
      final entry = CardIconEntry(
        iconName: 'delete',
        targetListId: 'test-uuid',
      );
      final json = entry.toJson();
      final recreated = CardIconEntry.fromJson(json);
      expect(recreated.iconName, entry.iconName);
      expect(recreated.targetListId, entry.targetListId);
    });
  });

  group('CardIconListConverter', () {
    const converter = CardIconListConverter();

    test('parses legacy array format', () {
      final legacyJson = [
        ['check_circle', 'uuid-1'],
        ['delete', 'uuid-2'],
      ];
      final result = converter.fromJson(legacyJson);
      expect(result.length, 2);
      expect(result[0].iconName, 'check_circle');
      expect(result[0].targetListId, 'uuid-1');
      expect(result[1].iconName, 'delete');
      expect(result[1].targetListId, 'uuid-2');
    });

    test('parses new object format', () {
      final newJson = [
        {'iconName': 'check_circle', 'targetListId': 'uuid-1'},
        {'iconName': 'delete', 'targetListId': 'uuid-2'},
      ];
      final result = converter.fromJson(newJson);
      expect(result.length, 2);
      expect(result[0].iconName, 'check_circle');
      expect(result[0].targetListId, 'uuid-1');
      expect(result[1].iconName, 'delete');
      expect(result[1].targetListId, 'uuid-2');
    });

    test('handles mixed format', () {
      final mixedJson = [
        ['check_circle', 'uuid-1'],
        {'iconName': 'delete', 'targetListId': 'uuid-2'},
      ];
      final result = converter.fromJson(mixedJson);
      expect(result.length, 2);
      expect(result[0].iconName, 'check_circle');
      expect(result[1].iconName, 'delete');
    });

    test('toJson outputs new format', () {
      final entries = [
        CardIconEntry(iconName: 'check_circle', targetListId: 'uuid-1'),
        CardIconEntry(iconName: 'delete', targetListId: 'uuid-2'),
      ];
      final json = converter.toJson(entries);
      expect(json.length, 2);
      expect(json[0], isA<Map>());
      expect((json[0] as Map)['iconName'], 'check_circle');
    });

    test('handles empty list', () {
      final result = converter.fromJson([]);
      expect(result, isEmpty);
    });
  });

  group('SortMode', () {
    test('all values exist', () {
      expect(SortMode.values, contains(SortMode.dateAscending));
      expect(SortMode.values, contains(SortMode.dateDescending));
      expect(SortMode.values, contains(SortMode.title));
      expect(SortMode.values, contains(SortMode.manual));
    });
  });
}
