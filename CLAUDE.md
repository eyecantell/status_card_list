# status_card_list

Generic card list engine for Flutter. Provides swipeable, draggable, expandable cards organized into configurable lists. Consuming apps supply a `CardListDataSource` implementation; the engine handles all UI, state management, and interactions.

First consumer: **contractmatch** (contract notice triage). See `CONTRACTMATCH_INTEGRATION.md` for that integration guide.

## Commands

```bash
# Run tests (123 tests)
flutter test

# Run a single test file
flutter test test/data_source/in_memory_data_source_test.dart

# Static analysis
dart analyze

# Regenerate Freezed/JSON code after changing models
dart run build_runner build --delete-conflicting-outputs

# Run the app (uses InMemoryDataSource with sample data)
flutter run -d chrome
```

## Architecture

**State management**: Riverpod 2.6 (StateNotifierProvider, FutureProvider, StateProvider)
**Models**: Freezed 2.5 immutable classes with JSON serialization
**Persistence**: SharedPreferences (InMemoryDataSource), HTTP REST (HttpDataSource)

### Data Flow

```
CardListDataSource (abstract interface)
    ├── InMemoryDataSource (local demo, SharedPreferences)
    └── HttpDataSource (REST client, consumer provides HttpResponseMapper)

dataSourceProvider (must be overridden in ProviderScope)
    ├── itemsProvider (current list items, StateNotifier)
    ├── listConfigsProvider (all list configs, StateNotifier)
    ├── itemCacheProvider (cross-list item cache, StateProvider)
    ├── itemToListIndexProvider (item→list mapping, StateProvider)
    └── actionsProvider (moveItem, reorderItems, loadItemDetail)
```

### Key Design Decisions

- **Two-tier item state**: `itemsProvider` holds items for the current list only. `itemCacheProvider` accumulates all items seen across lists (for cross-list lookups like related items). `itemToListIndexProvider` maps item ID → list ID.
- **On-demand detail loading**: `Item.html` is nullable. List responses can omit HTML for performance. When a card is expanded, `actionsProvider.loadItemDetail()` fetches the full content and updates the cache.
- **DataSource does sorting**: `loadItems(sortMode:)` is the primary sort path. HttpDataSource passes it to the server; InMemoryDataSource sorts locally. `ItemsNotifier.sortItems()` is kept as a public utility but isn't used in the main data flow.
- **No Stream/push**: Data changes use explicit `refresh()` calls, not streams. Deferred by design.

## Project Structure

```
lib/
├── data_source/
│   ├── card_list_data_source.dart   # Abstract interface — the contract consumers implement
│   ├── items_page.dart              # Pagination wrapper (items, totalCount, hasMore, offset)
│   ├── in_memory_data_source.dart   # Local implementation with SharedPreferences
│   ├── http_data_source.dart        # REST client + HttpResponseMapper interface
│   └── multi_context_data_source.dart  # Extension for multi-tenant (DataContext model)
├── models/
│   ├── item.dart                    # Item: id, title, subtitle, html?, dueDate?, status, extra
│   ├── list_config.dart             # ListConfig: uuid, name, swipeActions, buttons, cardIcons, sortMode, icon, color
│   ├── card_list_config.dart        # Builder callbacks for custom card rendering
│   └── sort_mode.dart               # Enum: dateAscending, dateDescending, title, manual, similarityDescending, deadlineSoonest, newest
├── providers/
│   ├── data_source_provider.dart    # Must be overridden in ProviderScope
│   ├── items_provider.dart          # itemsProvider, itemCacheProvider, itemToListIndexProvider, itemMapProvider
│   ├── lists_provider.dart          # listConfigsProvider, currentListIdProvider, currentListConfigProvider
│   ├── actions_provider.dart        # CardListActions: moveItem, reorderItems, loadItemDetail
│   ├── navigation_provider.dart     # navigateToItem (switch list + scroll + highlight)
│   ├── context_provider.dart        # dataContextsProvider, currentContextProvider (multi-tenant)
│   └── theme_provider.dart          # Light/dark theme toggle
├── screens/
│   └── home_screen.dart             # Main screen: app bar, sort dropdown, card list, drawer
├── widgets/
│   ├── drawer_menu.dart             # Navigation drawer: list selection, context switcher, counts
│   └── list_settings_dialog.dart    # List config editor (name, icon, color)
├── status_card.dart                 # Card widget: swipe, expand/collapse, action icons, related items
├── status_card_list.dart            # ReorderableListView wrapper for StatusCards
├── status_card_list_example.dart    # Bridge: transforms ListConfig.buttons → statusIcons for StatusCardList
├── utils/constants.dart             # Icon maps (iconMap, iconMapForLists), available colors, DefaultListIds
└── main.dart                        # App entry: initializes InMemoryDataSource, provides via ProviderScope
```

## How Consuming Apps Integrate

1. Implement `HttpResponseMapper` (4 methods: `parseItemsPage`, `parseItemDetail`, `parseListConfigs`, `parseStatus`)
2. Create `HttpDataSource` with your mapper, base URL, and default list ID
3. Override `dataSourceProvider` in `ProviderScope`
4. Optionally provide `CardListConfig` with custom builder callbacks

The engine's `HomeScreen` is the entry point. Consumers don't build their own screens — they configure the engine.

## Models

**Item** (Freezed): `id`, `title`, `subtitle`, `html?`, `dueDate?`, `status`, `relatedItemIds`, `extra` (Map<String, dynamic> for consumer-specific metadata)

**ListConfig** (Freezed): `uuid`, `name`, `swipeActions` (direction→targetListId), `buttons` (iconName→targetListId), `cardIcons` (list of CardIconEntry), `dueDateLabel`, `sortMode`, `iconName`, `colorValue`

**CardListConfig**: Optional builder callbacks — `collapsedBuilder`, `expandedBuilder`, `trailingBuilder`, `subtitleBuilder`. When null, engine uses default rendering.

## Tests

Tests use `InMemoryDataSource` with `SharedPreferences.setMockInitialValues({})`. HttpDataSource tests use `MockClient` from `package:http/testing.dart`.

```
test/
├── data_source/
│   ├── in_memory_data_source_test.dart  # All DataSource methods, default data, sorting, reorder
│   └── http_data_source_test.dart       # REST calls with MockClient, error handling, custom headers
├── models/
│   ├── item_test.dart                   # Nullable fields, extra, JSON round-trips, formatDueDateRelative
│   ├── list_config_test.dart            # Icon/color getters, defaults, JSON, copyWith, CardIconListConverter
│   └── card_list_config_test.dart       # Builder callbacks, widget tests
├── providers/
│   ├── items_provider_test.dart         # Loading, sorting (all 7 modes), null dueDate handling, cache
│   ├── lists_provider_test.dart         # Config loading, currentListId, setSortMode, updateConfig
│   ├── actions_provider_test.dart       # moveItem, reorderItems, loadItemDetail
│   └── context_provider_test.dart       # Non-multi-context returns empty, DataContext model
└── widget_test.dart                     # Full widget test: render items, switch lists via drawer
```

## Common Tasks

**Add a new sort mode**: Add to `SortMode` enum in `sort_mode.dart`, add case in `ItemsNotifier.sortItems()` in `items_provider.dart`, add label in `home_screen.dart` dropdown, regenerate with `build_runner`.

**Add a field to Item**: Edit `item.dart`, regenerate with `build_runner`, update `InMemoryDataSource` default data if needed, update mapper in consuming app.

**Add a new icon for cards/lists**: Add entry to `iconMap` or `iconMapForLists` in `utils/constants.dart`.
