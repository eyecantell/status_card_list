# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **`resetContextState()` helper** — canonical function in `context_provider.dart` that resets all context-dependent providers on context switch. Consuming apps should call this instead of manually resetting individual providers. Clears list ID, item cache, item-to-list index, navigation state, and invalidates async providers.
- **`CardListConfig.onContextChanged` callback** — optional `Future<void> Function(String contextId)?` that lets consuming apps handle context-switch provider mutations themselves. When provided, `DrawerMenu` delegates to the callback instead of performing internal invalidations. This decouples context-switching logic from library versioning.
- **Empty-state UI for contexts with no lists** — `HomeScreen` now shows "No lists available for this company." with a working drawer (for switching contexts) instead of an infinite spinner when `listConfigsProvider` loads successfully but returns an empty list.
- **Caller-defined sort options** — `SortOption` class replaces the hardcoded `SortMode` enum. Consumers define their own sort options using `byField()`, `byExtra()`, or custom comparators. No engine changes needed to add new sorts.
- **`Item.movedAt` field** — `DateTime?` stamped when an item is moved between lists. Enables "Recently Moved" sorting for trash/archive lists.
- **`CardListConfig.sortOptions`** — optional list of `SortOption` for the sort dropdown. Falls back to `SortOption.defaults` (Manual, Title, Date Ascending, Date Descending).
- **`InMemoryDataSource` accepts `sortOptions`** — optional constructor parameter for local sorting with custom sort options.
- **`InMemoryDataSource` persists items** — `_saveItemsToPrefs()` method saves items after mutation (e.g., `movedAt` stamp).
- **Undo on move** — snackbar with Undo button appears after moving an item via swipe or action icon. 5-second timeout.
- **`CardListConfig.drawerItems`** — optional `List<Widget>` to inject custom entries into the navigation drawer.
- **Optimistic card removal** — cards collapse and disappear immediately on move without waiting for data source refresh.
- **List item counts on startup** — `listCountsProvider` fetches counts via `getStatus()` without loading all items.
- **Tooltips on card action icons**
- **`docs/` directory** — guides for sorting, card interactions, and custom drawer items.

### Changed
- **`ListConfig.sortMode`** — type changed from `SortMode` enum to `String` (default `'manual'`). Backward compatible with persisted enum strings.
- **`CardListDataSource.loadItems(sortMode:)`** — parameter changed from `SortMode` to `String`.
- **Default sort mode** — changed from `dateAscending` to `'manual'` in the abstract interface. Individual list configs can still set their own defaults.
- **Sort dropdown** — now reads labels from `SortOption.label` instead of hardcoded switch statement.
- **Settings and theme toggle** — moved from AppBar actions to navigation drawer.
- **Sort button** — replaced text dropdown with icon-only popup to prevent AppBar overflow.
- **Card icon tap animation** — animates in matching swipe direction.
- **Undo snackbar styling** — outlined button with proper contrast in light/dark themes.

### Removed
- **`SortMode` enum** — deleted `sort_mode.dart` and `sort_mode.g.dart`. Replaced by `SortOption` class.
- **`ItemsNotifier.sortItems()` public method** — sorting logic moved to `SortOption` comparators and `InMemoryDataSource`.

### Fixed
- Card flash on move eliminated by optimistic removal
- Expanded card spinner not resolving after detail fetch
- Smooth collapse animation when card is moved to another list

## [2.0.0] - 2025-06-15

### Added
- **Riverpod state management** — replaced StatefulWidget-based state with Riverpod providers
  - `itemsProvider` — manages items state with async loading
  - `listConfigsProvider` — manages list configurations
  - `itemCacheProvider` — cross-list item cache
  - `itemToListIndexProvider` — item-to-list mapping
  - `navigationProvider` — handles expanded/navigated item state
  - `themeModeProvider` — controls light/dark theme toggle
- **Freezed models** — immutable data models with code generation
  - `Item` — immutable item model with `formatDueDateRelative()` method
  - `ListConfig` — immutable list configuration with computed `icon` and `color` getters
  - `CardIconEntry` — represents card action button configuration
- **CardListDataSource abstraction** — `InMemoryDataSource` and `HttpDataSource` implementations
- **`CardListConfig`** — builder callbacks for custom card rendering (`collapsedBuilder`, `expandedBuilder`, `trailingBuilder`, `subtitleBuilder`)
- **On-demand detail loading** — `Item.html` is nullable; fetched on card expand
- **`Item.extra`** — `Map<String, dynamic>` for consumer-specific metadata
- **Multi-context support** — `DataContext` model for multi-tenant switching
- **Local persistence** — data persists between sessions via SharedPreferences
- **Comprehensive test suite** — ~148 unit tests covering models, data sources, providers, and widgets

### Changed
- **Due date calculation** — uses `DateTime.now()` instead of hardcoded date
- **Card icons format** — `List<CardIconEntry>` with backward-compatible JSON parsing
- **File structure** — reorganized into `models/`, `providers/`, `data_source/`, `screens/`, `utils/`

### Removed
- `lib/app.dart` — replaced by `lib/screens/home_screen.dart`
- `lib/data.dart` — replaced by data sources with sample data
- Direct state mutation — replaced by immutable models and Riverpod

### Fixed
- Hardcoded date bug in due date formatting

## [1.0.0] - 2025-06-06

### Added
- Initial release with card-based list UI
- Multiple list support (Review, Saved, Trash)
- Swipe gestures to move items between lists
- Card action buttons for quick item movement
- Related items with navigation
- Manual drag-and-drop reordering
- Sort by date (ascending/descending), title, or manual order
- List customization (icon, color, swipe actions, card buttons)
- Light/dark theme toggle
- Expandable HTML content in cards
