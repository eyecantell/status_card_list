# Sorting

The engine's sort system is fully caller-defined. You provide `SortOption` objects that describe how items can be sorted; the engine displays them in a dropdown and passes the selected sort ID to the DataSource.

## Quick Start

```dart
import 'package:status_card_list/models/sort_option.dart';
import 'package:status_card_list/models/card_list_config.dart';

// 1. Define your sort options
final sortOptions = [
  SortOption.manual,
  SortOption.byField(
    id: 'dateAscending',
    label: 'Date Ascending',
    field: (item) => item.dueDate,
  ),
  SortOption.byField(
    id: 'title',
    label: 'Title',
    field: (item) => item.title,
  ),
];

// 2. Pass to CardListConfig (for the UI dropdown)
final cardListConfig = CardListConfig(
  sortOptions: sortOptions,
);

// 3. Pass to InMemoryDataSource (for local sorting)
final dataSource = InMemoryDataSource(prefs, sortOptions: sortOptions);
```

If you don't provide `sortOptions`, the engine uses `SortOption.defaults` which includes: Manual, Title, Date Ascending, and Date Descending.

## Creating Sort Options

### Manual (preserve order)

```dart
SortOption.manual  // static const, id: 'manual'
```

Manual sort preserves insertion order (no comparator). This is automatically set when the user drag-to-reorders items.

### Sort by an Item field

Use `byField` to sort by any first-class field on `Item`. Null values sort last.

```dart
// Ascending (default)
SortOption.byField(
  id: 'dateAscending',
  label: 'Date Ascending',
  field: (item) => item.dueDate,
)

// Descending
SortOption.byField(
  id: 'dateDescending',
  label: 'Date Descending',
  field: (item) => item.dueDate,
  descending: true,
)

// Sort by title
SortOption.byField(
  id: 'title',
  label: 'Title',
  field: (item) => item.title,
)

// Sort by movedAt (recently moved items first)
SortOption.byField(
  id: 'recentlyMoved',
  label: 'Recently Moved',
  field: (item) => item.movedAt,
  descending: true,
)
```

The `field` callback extracts a `Comparable` value from the item. The type parameter is inferred automatically.

### Sort by an extra metadata field

Use `byExtra` to sort by a key in `item.extra`. Missing keys sort last.

```dart
SortOption.byExtra(
  id: 'similarity',
  label: 'Best Match',
  key: 'best_similarity',
  descending: true,
)

SortOption.byExtra(
  id: 'priority',
  label: 'Priority',
  key: 'priority_score',
)
```

### Custom comparator

For full control, provide a comparator directly:

```dart
SortOption(
  id: 'custom',
  label: 'Custom Sort',
  comparator: (a, b) {
    // Your logic here
    return a.title.length.compareTo(b.title.length);
  },
)
```

## Where Sort Options Are Used

Sort options appear in **two places** that are intentionally decoupled:

| Location | Purpose |
|----------|---------|
| `CardListConfig.sortOptions` | Populates the sort dropdown in the UI |
| `InMemoryDataSource(sortOptions:)` | Used for local sorting when `loadItems()` is called |

Define your sort options list once and pass it to both:

```dart
final mySortOptions = [SortOption.manual, /* ... */];

// UI
HomeScreen(cardListConfig: CardListConfig(sortOptions: mySortOptions));

// DataSource
InMemoryDataSource(prefs, sortOptions: mySortOptions);
```

`HttpDataSource` does **not** need sort options -- it passes the sort mode ID string to the server as a query parameter (`?sort=dateAscending`), and the server handles sorting.

## How It Works Internally

1. User selects a sort option from the dropdown
2. `ListConfig.sortMode` is updated with the option's `id` string (e.g., `'dateAscending'`)
3. `itemsProvider` calls `dataSource.loadItems(sortMode: 'dateAscending')`
4. `InMemoryDataSource` finds the `SortOption` with matching ID and applies its comparator
5. If no matching option is found, items are returned unsorted (same as manual)

## The `movedAt` Field

`Item.movedAt` is a `DateTime?` that records when an item was last moved between lists. It's stamped automatically by:

- `InMemoryDataSource.moveItem()` -- persists to SharedPreferences
- `actionsProvider.moveItem()` -- optimistic update in the client cache

This enables "Recently Moved" sorting for trash/archive lists:

```dart
SortOption.byField(
  id: 'recentlyMoved',
  label: 'Recently Moved',
  field: (item) => item.movedAt,
  descending: true,
)
```

Items that have never been moved (`movedAt == null`) sort last.

## Defaults

`SortOption.defaults` returns:

| ID | Label | Behavior |
|----|-------|----------|
| `manual` | Manual | Preserve insertion order |
| `title` | Title | Alphabetical by title |
| `dateAscending` | Date Ascending | Earliest due date first, nulls last |
| `dateDescending` | Date Descending | Latest due date first, nulls last |

## Migration from SortMode Enum

The engine previously hardcoded a `SortMode` enum (`dateAscending`, `dateDescending`, `title`, `manual`, `similarityDescending`, `deadlineSoonest`, `newest`). This has been replaced with caller-defined `SortOption` objects and a `String` sort mode ID.

### What changed

| Before | After |
|--------|-------|
| `SortMode` enum (7 values) | `SortOption` class (caller defines any number) |
| `ListConfig.sortMode` was `SortMode` | `ListConfig.sortMode` is `String` (default `'manual'`) |
| `loadItems(sortMode: SortMode.dateAscending)` | `loadItems(sortMode: 'dateAscending')` |
| `setSortMode(listId, SortMode.manual)` | `setSortMode(listId, 'manual')` |
| Sort labels hardcoded in `home_screen.dart` | Sort labels come from `SortOption.label` |
| `ItemsNotifier.sortItems()` public method | Removed (sorting lives in DataSource / SortOption) |

### HttpResponseMapper changes

If your mapper was mapping `sort_mode` from the API to a `SortMode` enum value, change it to pass the string directly:

```dart
// Before
ListConfig(
  sortMode: SortMode.similarityDescending,
  // ...
)

// After
ListConfig(
  sortMode: 'similarityDescending',  // just a string now
  // ...
)
```

### Server-side sort IDs

For `HttpDataSource`, the `SortOption.id` is sent as the `?sort=` query parameter. Your sort option IDs **must match what the server expects**. If your server handles `?sort=similarityDescending`, your sort option must use `id: 'similarityDescending'`.

### Default sort per list

`ListConfig.sortMode` stores the *currently selected* sort for that list. The default comes from wherever the config is created:

- **HttpDataSource**: The server returns `sort_mode` per list in the `/lists` response. Your mapper puts this string into `ListConfig.sortMode`.
- **InMemoryDataSource**: The default configs set `sortMode:` explicitly (e.g., `sortMode: 'dateAscending'`).

If the server returns `sort_mode: 'similarityDescending'` for the Review list, that's what the dropdown will show as selected on load.

### JSON backward compatibility

The old `@JsonEnum` serialized enum values as strings (e.g., `"sortMode": "dateAscending"`). Since the field is now a plain `String`, these existing persisted values are read correctly with no migration needed.

## Contractmatch Example

Contractmatch uses five sort modes across three lists, with `best_similarity` as the primary sort for triage:

### Sort options

```dart
final contractmatchSortOptions = [
  SortOption.manual,
  SortOption.byExtra(
    id: 'similarityDescending',
    label: 'Best Match',
    key: 'best_similarity',
    descending: true,
  ),
  SortOption.byField(
    id: 'deadlineSoonest',
    label: 'Deadline Soonest',
    field: (item) => item.dueDate,
  ),
  SortOption.byField(
    id: 'newest',
    label: 'Newest',
    field: (item) => item.dueDate,
    descending: true,
  ),
  SortOption.byField(
    id: 'title',
    label: 'Title',
    field: (item) => item.title,
  ),
  SortOption.byField(
    id: 'recentlyMoved',
    label: 'Recently Moved',
    field: (item) => item.movedAt,
    descending: true,
  ),
];
```

### Wiring it up

```dart
HomeScreen(
  cardListConfig: CardListConfig(
    sortOptions: contractmatchSortOptions,
    collapsedBuilder: /* ... */,
    expandedBuilder: /* ... */,
    // ...
  ),
)
```

For `HttpDataSource`, no `sortOptions` parameter is needed — the server sorts. The IDs (`similarityDescending`, `deadlineSoonest`, etc.) are sent as `?sort=` query params and must match the server's expected values.

### Default sort per list

The server's `/lists` endpoint returns the default sort per list:

| List | Default `sort_mode` |
|------|-------------------|
| Review | `similarityDescending` |
| Saved | `similarityDescending` |
| Trash | `newest` |

The `HttpResponseMapper.parseListConfigs()` maps this into `ListConfig.sortMode`:

```dart
@override
List<ListConfig> parseListConfigs(List<dynamic> json) {
  return json.map((j) {
    final map = j as Map<String, dynamic>;
    return ListConfig(
      uuid: map['id'] as String,
      name: map['name'] as String,
      sortMode: map['sort_mode'] as String? ?? 'similarityDescending',
      // ... other fields
    );
  }).toList();
}
```

### What the server receives

When the user changes sort in the dropdown:

```
GET /api/notices?list_id=review&sort=similarityDescending&limit=50&offset=0
GET /api/notices?list_id=review&sort=deadlineSoonest&limit=50&offset=0
GET /api/notices?list_id=trash&sort=recentlyMoved&limit=50&offset=0
```

The server must handle these sort values. For `recentlyMoved`, the server would sort by its own `moved_at` column (the engine stamps `Item.movedAt` client-side for optimistic UI, but the server is the source of truth on reload).

## Tips

- The `'manual'` sort ID is special: the engine sets it automatically after drag-to-reorder. Use `SortOption.manual.id` instead of raw `'manual'` strings for safer references.
- Equality is based on `id` only, so two `SortOption` instances with the same `id` are considered equal regardless of label or comparator.
- `SortOption` is a plain Dart class (not Freezed) because `Comparator` functions can't be serialized.
- `ListConfig.sortMode` defaults to `'manual'`. Existing persisted data with old enum strings (e.g., `"dateAscending"`) will be read as-is since they're now just strings.
