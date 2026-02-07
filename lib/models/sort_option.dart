import 'item.dart';

/// Caller-defined sort option. The engine displays these in the sort dropdown
/// and passes the selected `id` to the DataSource.
///
/// Use the factory constructors for common patterns:
/// - `SortOption.byField` for sorting by a first-class Item field
/// - `SortOption.byExtra` for sorting by a key in item.extra
/// - `SortOption(id:, label:, comparator:)` for full custom control
/// - `SortOption.manual` for preserve-order (no sort)
class SortOption {
  final String id;
  final String label;

  /// Comparator used by InMemoryDataSource for local sorting.
  /// Null means "preserve insertion order" (manual/drag-to-reorder).
  /// HttpDataSource ignores this — the server sorts by the `id` string.
  final Comparator<Item>? comparator;

  const SortOption({
    required this.id,
    required this.label,
    this.comparator,
  });

  /// Manual sort: preserve insertion order (no comparator).
  static const manual = SortOption(id: 'manual', label: 'Manual');

  /// Sort by a typed field on Item. Nulls sort last.
  static SortOption byField<T extends Comparable<T>>({
    required String id,
    required String label,
    required T? Function(Item) field,
    bool descending = false,
  }) {
    return SortOption(
      id: id,
      label: label,
      comparator: (a, b) {
        final aVal = field(a);
        final bVal = field(b);
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return 1;
        if (bVal == null) return -1;
        return descending ? bVal.compareTo(aVal) : aVal.compareTo(bVal);
      },
    );
  }

  /// Sort by a key in item.extra. Values must be Comparable. Nulls/missing sort last.
  static SortOption byExtra({
    required String id,
    required String label,
    required String key,
    bool descending = false,
  }) {
    return SortOption(
      id: id,
      label: label,
      comparator: (a, b) {
        final aVal = a.extra[key] as Comparable?;
        final bVal = b.extra[key] as Comparable?;
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return 1;
        if (bVal == null) return -1;
        return descending ? bVal.compareTo(aVal) : aVal.compareTo(bVal);
      },
    );
  }

  /// Default sort options when the caller doesn't specify any.
  static List<SortOption> get defaults => [
        manual,
        byField(
          id: 'title',
          label: 'Title',
          field: (i) => i.title,
        ),
        byField(
          id: 'dateAscending',
          label: 'Date Ascending',
          field: (i) => i.dueDate,
        ),
        byField(
          id: 'dateDescending',
          label: 'Date Descending',
          field: (i) => i.dueDate,
          descending: true,
        ),
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SortOption && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
