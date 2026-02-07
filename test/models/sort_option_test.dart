import 'package:flutter_test/flutter_test.dart';
import 'package:status_card_list/models/item.dart';
import 'package:status_card_list/models/sort_option.dart';

void main() {
  group('SortOption', () {
    test('manual has null comparator', () {
      expect(SortOption.manual.id, 'manual');
      expect(SortOption.manual.label, 'Manual');
      expect(SortOption.manual.comparator, isNull);
    });

    group('byField', () {
      test('ascending sort works correctly', () {
        final option = SortOption.byField(
          id: 'title',
          label: 'Title',
          field: (i) => i.title,
        );

        final items = [
          Item(id: '1', title: 'C Task', subtitle: '', status: 'Open'),
          Item(id: '2', title: 'A Task', subtitle: '', status: 'Open'),
          Item(id: '3', title: 'B Task', subtitle: '', status: 'Open'),
        ];

        final sorted = [...items]..sort(option.comparator!);
        expect(sorted[0].title, 'A Task');
        expect(sorted[1].title, 'B Task');
        expect(sorted[2].title, 'C Task');
      });

      test('descending sort works correctly', () {
        final option = SortOption.byField(
          id: 'titleDesc',
          label: 'Title Desc',
          field: (i) => i.title,
          descending: true,
        );

        final items = [
          Item(id: '1', title: 'A Task', subtitle: '', status: 'Open'),
          Item(id: '2', title: 'C Task', subtitle: '', status: 'Open'),
          Item(id: '3', title: 'B Task', subtitle: '', status: 'Open'),
        ];

        final sorted = [...items]..sort(option.comparator!);
        expect(sorted[0].title, 'C Task');
        expect(sorted[1].title, 'B Task');
        expect(sorted[2].title, 'A Task');
      });

      test('handles nulls (nulls sort last)', () {
        final option = SortOption.byField(
          id: 'dateAsc',
          label: 'Date Asc',
          field: (i) => i.dueDate,
        );

        final items = [
          Item(id: '1', title: 'No date', subtitle: '', status: 'Open'),
          Item(
            id: '2',
            title: 'Has date',
            subtitle: '',
            status: 'Open',
            dueDate: DateTime(2025, 1, 10),
          ),
          Item(id: '3', title: 'Also no date', subtitle: '', status: 'Open'),
        ];

        final sorted = [...items]..sort(option.comparator!);
        expect(sorted[0].id, '2'); // Has date comes first
        expect(sorted[1].dueDate, isNull); // Nulls last
        expect(sorted[2].dueDate, isNull);
      });

      test('with movedAt works (recently moved sort)', () {
        final option = SortOption.byField(
          id: 'recentlyMoved',
          label: 'Recently Moved',
          field: (i) => i.movedAt,
          descending: true,
        );

        final items = [
          Item(
            id: '1',
            title: 'Older move',
            subtitle: '',
            status: 'Open',
            movedAt: DateTime(2025, 1, 1),
          ),
          Item(
            id: '2',
            title: 'Newest move',
            subtitle: '',
            status: 'Open',
            movedAt: DateTime(2025, 3, 1),
          ),
          Item(id: '3', title: 'Never moved', subtitle: '', status: 'Open'),
        ];

        final sorted = [...items]..sort(option.comparator!);
        expect(sorted[0].id, '2'); // Most recent
        expect(sorted[1].id, '1'); // Older
        expect(sorted[2].id, '3'); // Null (never moved) last
      });
    });

    group('byExtra', () {
      test('works correctly', () {
        final option = SortOption.byExtra(
          id: 'similarity',
          label: 'Best Match',
          key: 'best_similarity',
          descending: true,
        );

        final items = [
          Item(
            id: '1',
            title: 'Low',
            subtitle: '',
            status: 'Open',
            extra: {'best_similarity': 0.3},
          ),
          Item(
            id: '2',
            title: 'High',
            subtitle: '',
            status: 'Open',
            extra: {'best_similarity': 0.9},
          ),
          Item(
            id: '3',
            title: 'Mid',
            subtitle: '',
            status: 'Open',
            extra: {'best_similarity': 0.6},
          ),
        ];

        final sorted = [...items]..sort(option.comparator!);
        expect(sorted[0].id, '2'); // 0.9
        expect(sorted[1].id, '3'); // 0.6
        expect(sorted[2].id, '1'); // 0.3
      });

      test('handles missing keys (nulls sort last)', () {
        final option = SortOption.byExtra(
          id: 'score',
          label: 'Score',
          key: 'score',
          descending: true,
        );

        final items = [
          Item(id: '1', title: 'No score', subtitle: '', status: 'Open'),
          Item(
            id: '2',
            title: 'Has score',
            subtitle: '',
            status: 'Open',
            extra: {'score': 42},
          ),
          Item(id: '3', title: 'Also no score', subtitle: '', status: 'Open'),
        ];

        final sorted = [...items]..sort(option.comparator!);
        expect(sorted[0].id, '2'); // Has score comes first
        expect(sorted[1].extra.containsKey('score'), isFalse);
        expect(sorted[2].extra.containsKey('score'), isFalse);
      });
    });

    group('defaults', () {
      test('contains expected entries', () {
        final defaults = SortOption.defaults;
        expect(defaults.length, 4);
        expect(defaults.map((o) => o.id), containsAll(['manual', 'title', 'dateAscending', 'dateDescending']));
      });

      test('manual is first', () {
        expect(SortOption.defaults[0].id, 'manual');
      });
    });

    group('equality', () {
      test('equality by id', () {
        final a = SortOption(id: 'test', label: 'Test A');
        final b = SortOption(id: 'test', label: 'Test B');
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('different id means not equal', () {
        final a = SortOption(id: 'a', label: 'A');
        final b = SortOption(id: 'b', label: 'B');
        expect(a, isNot(equals(b)));
      });
    });

    test('unknown sort ID falls back gracefully', () {
      // When InMemoryDataSource can't find a sort option, it returns items unsorted.
      // Test this at the SortOption level: if comparator is null, items stay as-is.
      const option = SortOption(id: 'unknown', label: 'Unknown');
      expect(option.comparator, isNull);
    });
  });
}
