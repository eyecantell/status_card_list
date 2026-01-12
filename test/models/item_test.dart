import 'package:flutter_test/flutter_test.dart';
import 'package:status_card_list/models/item.dart';

void main() {
  group('Item', () {
    late Item testItem;
    late DateTime referenceDate;

    setUp(() {
      referenceDate = DateTime(2025, 5, 22);
      testItem = Item(
        id: '1',
        title: 'Test Task',
        subtitle: 'Test Subtitle',
        html: '<p>Test HTML</p>',
        dueDate: referenceDate,
        status: 'Open',
        relatedItemIds: ['2', '3'],
      );
    });

    group('formatDueDateRelative', () {
      test('returns "today" for same day', () {
        final result = testItem.formatDueDateRelative(referenceDate);
        expect(result, contains('today'));
        expect(result, contains('5/22/2025'));
      });

      test('returns "tomorrow" for next day', () {
        final item = testItem.copyWith(
          dueDate: referenceDate.add(const Duration(days: 1)),
        );
        final result = item.formatDueDateRelative(referenceDate);
        expect(result, contains('tomorrow'));
        expect(result, contains('5/23/2025'));
      });

      test('returns "yesterday" for previous day', () {
        final item = testItem.copyWith(
          dueDate: referenceDate.subtract(const Duration(days: 1)),
        );
        final result = item.formatDueDateRelative(referenceDate);
        expect(result, contains('yesterday'));
        expect(result, contains('5/21/2025'));
      });

      test('returns "in X days" for future dates', () {
        final item = testItem.copyWith(
          dueDate: referenceDate.add(const Duration(days: 5)),
        );
        final result = item.formatDueDateRelative(referenceDate);
        expect(result, contains('in 5 days'));
      });

      test('returns "X days ago" for past dates', () {
        final item = testItem.copyWith(
          dueDate: referenceDate.subtract(const Duration(days: 3)),
        );
        final result = item.formatDueDateRelative(referenceDate);
        expect(result, contains('3 days ago'));
      });

      test('uses current date when no reference provided', () {
        // This test verifies the method works without arguments
        final result = testItem.formatDueDateRelative();
        expect(result, isNotEmpty);
      });
    });

    group('isOverdue', () {
      test('returns true when due date is in the past', () {
        final item = Item(
          id: '1',
          title: 'Past Task',
          subtitle: 'Overdue',
          html: '',
          dueDate: DateTime.now().subtract(const Duration(days: 1)),
          status: 'Open',
        );
        expect(item.isOverdue, isTrue);
      });

      test('returns false when due date is in the future', () {
        final item = Item(
          id: '1',
          title: 'Future Task',
          subtitle: 'Not Due',
          html: '',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          status: 'Open',
        );
        expect(item.isOverdue, isFalse);
      });
    });

    group('JSON serialization', () {
      test('toJson creates valid JSON map', () {
        final json = testItem.toJson();
        expect(json['id'], '1');
        expect(json['title'], 'Test Task');
        expect(json['subtitle'], 'Test Subtitle');
        expect(json['html'], '<p>Test HTML</p>');
        expect(json['status'], 'Open');
        expect(json['relatedItemIds'], ['2', '3']);
        expect(json['dueDate'], isA<String>());
      });

      test('fromJson creates Item from JSON map', () {
        final json = testItem.toJson();
        final recreatedItem = Item.fromJson(json);
        expect(recreatedItem.id, testItem.id);
        expect(recreatedItem.title, testItem.title);
        expect(recreatedItem.subtitle, testItem.subtitle);
        expect(recreatedItem.html, testItem.html);
        expect(recreatedItem.status, testItem.status);
        expect(recreatedItem.relatedItemIds, testItem.relatedItemIds);
      });

      test('handles empty relatedItemIds', () {
        final item = Item(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          html: '',
          dueDate: DateTime.now(),
          status: 'Open',
        );
        final json = item.toJson();
        final recreated = Item.fromJson(json);
        expect(recreated.relatedItemIds, isEmpty);
      });
    });

    group('copyWith', () {
      test('creates copy with modified title', () {
        final copy = testItem.copyWith(title: 'New Title');
        expect(copy.title, 'New Title');
        expect(copy.id, testItem.id);
        expect(copy.subtitle, testItem.subtitle);
      });

      test('creates copy with modified relatedItemIds', () {
        final copy = testItem.copyWith(relatedItemIds: ['4', '5', '6']);
        expect(copy.relatedItemIds, ['4', '5', '6']);
        expect(copy.id, testItem.id);
      });
    });

    group('equality', () {
      test('two items with same values are equal', () {
        final item1 = Item(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          html: '',
          dueDate: DateTime(2025, 1, 1),
          status: 'Open',
        );
        final item2 = Item(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          html: '',
          dueDate: DateTime(2025, 1, 1),
          status: 'Open',
        );
        expect(item1, equals(item2));
      });

      test('two items with different values are not equal', () {
        final item1 = Item(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          html: '',
          dueDate: DateTime(2025, 1, 1),
          status: 'Open',
        );
        final item2 = item1.copyWith(title: 'Different');
        expect(item1, isNot(equals(item2)));
      });
    });
  });
}
