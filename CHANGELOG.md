# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Riverpod state management** - Replaced StatefulWidget-based state with Riverpod providers
  - `itemsProvider` - Manages items state with async loading
  - `listConfigsProvider` - Manages list configurations
  - `itemListsProvider` - Manages item-to-list mappings
  - `navigationProvider` - Handles expanded/navigated item state
  - `themeModeProvider` - Controls light/dark theme toggle
- **Freezed models** - Immutable data models with code generation
  - `Item` - Immutable item model with `formatDueDateRelative()` method
  - `ListConfig` - Immutable list configuration with computed `icon` and `color` getters
  - `CardIconEntry` - Represents card action button configuration
  - `SortMode` - Enum with JSON serialization support
- **Repository pattern** - Data access layer with SharedPreferences persistence
  - `ItemRepository` - CRUD operations for items
  - `ListConfigRepository` - CRUD operations for list configs and item mappings
- **Local persistence** - Data now persists between app sessions via SharedPreferences
- **Comprehensive test suite** - 94 unit tests covering models, repositories, and providers
- **Constants file** - Centralized icon maps, colors, and default list IDs in `lib/utils/constants.dart`
- **Home screen** - New `HomeScreen` widget using `ConsumerStatefulWidget`

### Changed
- **Due date calculation** - Now uses `DateTime.now()` instead of hardcoded date (was May 22, 2025)
- **Card icons format** - Changed from `List<MapEntry<String, String>>` to `List<CardIconEntry>` with backward-compatible JSON parsing
- **List settings dialog** - Now uses `copyWith` for immutable updates instead of mutating config directly
- **File structure** - Reorganized into `models/`, `providers/`, `repositories/`, `screens/`, `utils/` directories

### Removed
- `lib/app.dart` - Replaced by `lib/screens/home_screen.dart`
- `lib/data.dart` - Replaced by repositories with sample data
- `lib/item.dart` - Replaced by `lib/models/item.dart`
- `lib/list_config.dart` - Replaced by `lib/models/list_config.dart`
- `lib/theme_config.dart` - Replaced by `lib/providers/theme_provider.dart`

### Fixed
- Hardcoded date bug in due date formatting (was always showing relative to May 22, 2025)

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
