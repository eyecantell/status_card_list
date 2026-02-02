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
        final result = testItem.formatDueDateRelative();
        expect(result, isNotEmpty);
      });

      test('returns "No deadline" when dueDate is null', () {
        final item = testItem.copyWith(dueDate: null);
        final result = item.formatDueDateRelative(referenceDate);
        expect(result, 'No deadline');
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

      test('returns false when dueDate is null', () {
        final item = Item(
          id: '1',
          title: 'No Date Task',
          subtitle: 'No deadline',
          status: 'Open',
        );
        expect(item.isOverdue, isFalse);
      });
    });

    group('nullable fields', () {
      test('html can be null', () {
        final item = Item(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          status: 'Open',
        );
        expect(item.html, isNull);
      });

      test('dueDate can be null', () {
        final item = Item(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          status: 'Open',
        );
        expect(item.dueDate, isNull);
      });

      test('html and dueDate can be provided', () {
        final now = DateTime.now();
        final item = Item(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          html: '<p>Content</p>',
          dueDate: now,
          status: 'Open',
        );
        expect(item.html, '<p>Content</p>');
        expect(item.dueDate, now);
      });
    });

    group('extra field', () {
      test('defaults to empty map', () {
        final item = Item(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          status: 'Open',
        );
        expect(item.extra, isEmpty);
      });

      test('accepts arbitrary metadata', () {
        final item = Item(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          status: 'Open',
          extra: {'best_similarity': 0.95, 'source': 'api'},
        );
        expect(item.extra['best_similarity'], 0.95);
        expect(item.extra['source'], 'api');
      });

      test('extra field round-trips through JSON', () {
        final item = Item(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          status: 'Open',
          extra: {'score': 42, 'tags': ['a', 'b']},
        );
        final json = item.toJson();
        final recreated = Item.fromJson(json);
        expect(recreated.extra['score'], 42);
        expect(recreated.extra['tags'], ['a', 'b']);
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

      test('handles null html in JSON round-trip', () {
        final item = Item(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          status: 'Open',
        );
        final json = item.toJson();
        final recreated = Item.fromJson(json);
        expect(recreated.html, isNull);
      });

      test('handles null dueDate in JSON round-trip', () {
        final item = Item(
          id: '1',
          title: 'Test',
          subtitle: 'Sub',
          status: 'Open',
        );
        final json = item.toJson();
        final recreated = Item.fromJson(json);
        expect(recreated.dueDate, isNull);
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
