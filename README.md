# status_card_list

A reusable Flutter package for displaying and organizing items as cards within lists. This package is designed to be generic and adaptable for various applications, with its initial development tailored for ContractMatch, a project that presents contracts matching a company's capability sets.

## Purpose

`status_card_list` provides a flexible and customizable UI component for Flutter applications that need to display items in a card-based list format. It supports features like task names, due dates, swipe actions, card action icons, and theme toggling, making it suitable for task management, status tracking, or any scenario requiring organized, card-based layouts.

## Current Functionality

- Displays a list of items as cards with a dark-themed UI (toggleable to light theme)
- Each card includes:
  - A title (e.g., "Task 1", "Task 2")
  - A subtitle for additional details (e.g., "Due today", "Due tomorrow")
  - Interaction elements such as swipe actions and customizable card icons for moving items between lists (e.g., "Review", "Saved", "Trash")
  - Expandable HTML content for detailed views
  - Related items with cross-list navigation
- Consistent icon usage across the sidebar menu, list title, and card action buttons
- Supports manual reordering, sorting by date or title, and list settings customization
- **Local persistence** - Data persists between app sessions via SharedPreferences
- Runs locally for development and testing across multiple platforms (web, desktop, mobile)
- Can move cards with mouse or gestures
- Cannot create new lists yet, or add comments/descriptions to lists

## Architecture

The app uses a clean, pragmatic architecture with **Riverpod** state management:

```
lib/
├── models/                    # Immutable models with freezed
│   ├── item.dart              # Item model with due date formatting
│   ├── list_config.dart       # List configuration with CardIconEntry
│   └── sort_mode.dart         # Sorting enum
├── providers/                 # Riverpod providers with business logic
│   ├── items_provider.dart    # Items state and CRUD operations
│   ├── lists_provider.dart    # List configs and item-to-list mappings
│   ├── navigation_provider.dart # Expand/navigate/scroll state
│   └── theme_provider.dart    # Light/dark theme toggle
├── repositories/              # Data access layer
│   ├── item_repository.dart   # Item persistence
│   └── list_config_repository.dart # Config and mapping persistence
├── screens/                   # Main screens
│   └── home_screen.dart       # Primary UI with ConsumerStatefulWidget
├── widgets/                   # UI components
│   ├── status_card.dart       # Individual card widget
│   ├── status_card_list.dart  # Reorderable list of cards
│   ├── drawer_menu.dart       # Navigation drawer
│   └── list_settings_dialog.dart # List customization dialog
├── utils/                     # Shared utilities
│   └── constants.dart         # Icons, colors, default IDs
└── main.dart                  # Entry point with ProviderScope
```

### Key Technologies

- **Riverpod** - State management with `StateNotifier`, `Provider`, and `AsyncValue`
- **Freezed** - Immutable data models with code generation
- **SharedPreferences** - Local data persistence
- **flutter_html** - HTML content rendering in cards

## Getting Started

This package can be integrated into any Flutter project requiring a card-based list interface. Follow these steps to use it in your project:

### Prerequisites

- Flutter SDK (version 3.29.2 or later recommended).
- Dart (included with Flutter).
- A code editor (e.g., Visual Studio Code with Flutter extension).
- Google Chrome for web development and mobile simulation.

### Installation

1. Clone the repository for development or testing:

   ```bash
   git clone <your-repo-url>
   cd status_card_list
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Generate code (required for freezed models):

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### Running the App

1. **Run on Chrome (Web)**:

   - Use the following command to run the app in Chrome:

     ```bash
     flutter run -d chrome
     ```
   - This opens the app in your default Chrome browser on your laptop.

2. **Simulate Mobile Devices in Chrome**:

   - To preview how the app looks on a phone:
     - Open Chrome DevTools by right-clicking on the page and selecting **Inspect**, or press `Ctrl + Shift + I` (Windows/Linux) or `Cmd + Option + I` (Mac).
     - Click the **Toggle Device Toolbar** icon (a small rectangle with a phone and tablet) in the top-left corner of DevTools, or press `Ctrl + Shift + M` (Windows/Linux) or `Cmd + Shift + M` (Mac).
     - Select a mobile device from the dropdown menu (e.g., "iPhone 14", "Pixel 7") to simulate its screen size, or enter a custom width and height (e.g., 375x667 for an iPhone SE).
     - Adjust the orientation (portrait/landscape) using the toolbar options and test the layout.
   - Use `r` in the terminal to hot reload after making code changes.

3. **Alternative Platforms**:

   - For a physical device or emulator, use `flutter devices` to list available devices, then run `flutter run -d <device_id>`. Set up an Android emulator (via Android Studio) or iOS Simulator (via Xcode) for more accurate testing.

### Running Tests

Run the full test suite:

```bash
flutter test
```

The test suite includes 94 tests covering:
- **Models** - Item due date formatting, ListConfig icon/color getters, JSON serialization
- **Repositories** - CRUD operations, SharedPreferences persistence
- **Providers** - State management, sorting, item movement between lists

### Development Notes

- The app uses a dark theme by default, toggleable via the theme button in the AppBar
- Icons for lists (e.g., `Icons.rate_review` for "Review") are consistent across the sidebar menu, list title, and card action buttons
- Customize list settings (e.g., swipe actions, card icons) via the settings dialog accessible from the AppBar
- Data persists automatically via SharedPreferences - changes survive app restarts
- After modifying freezed models, regenerate code with: `dart run build_runner build`

## ContractMatch Use Case

This package was initially developed to support ContractMatch, where contracts are presented as cards with details and actions to move them between review, saved, and trash states. The expandable HTML content allows for detailed contract information, and the swipe/reorder features aid in managing contract workflows.

## Future Enhancements

- Add ability to create new lists and add list descriptions
- Add support for additional sorting options or filters
- Enhance mobile responsiveness with media query adjustments
- Integrate with a backend API for real-time data syncing
- Add search/filter functionality across items