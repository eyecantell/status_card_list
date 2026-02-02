# Status Card List - Requirements Document

## Overview
A reusable Flutter package for displaying and managing items in customizable card-based lists. The package should be generic and adaptable for various applications (task management, contract tracking, etc.).

## Current Capabilities

### 1. Data Model

#### Items
- **Unique identifier** (UUID/string ID)
- **Title** - Main item name
- **Subtitle** - Additional context/status text
- **HTML Content** - Rich text content for expanded view
- **Due Date** - DateTime for sorting and display
- **Status** - String field for current state
- **Related Items** - List of IDs linking to other items

#### Lists
- **Unique identifier** (UUID)
- **Name** - Display name for the list
- **Icon** - Visual identifier (from predefined set)
- **Color** - Theme color for the list
- **Sort Mode** - Manual, Date Ascending, Date Descending, or Title
- **Due Date Label** - Customizable label text
- **Swipe Actions** - Left/right swipe target lists
- **Card Action Buttons** - Up to 5 configurable quick action buttons
- **Card Icons Configuration** - Which icons to display on cards in this list

### 2. List Management

#### Display
- Sidebar drawer menu showing all available lists
- Item count badge on each list in drawer
- Visual indicators (icon, color) for each list
- Highlight current active list

#### Navigation
- Switch between lists via drawer selection
- Deep linking to specific items across lists
- Auto-scroll to item when navigating from related items
- Visual highlight effect when item is navigated to

### 3. Item Display & Interaction

#### Card Display
- Title and subtitle/status visible when collapsed
- Due date with relative time formatting (today, tomorrow, in X days, X days ago)
- Count of related items
- Expandable to show full HTML content
- Related items shown as clickable links in expanded view
- List name shown next to related item links

#### Card Actions
- **Tap to expand/collapse** - Toggle HTML content visibility
- **Swipe gestures** - Left/right swipe to move to different lists
  - Visual feedback showing target list color/icon
  - Swipe threshold for action trigger
  - Smooth animations for card movement
- **Action buttons** - Up to 5 configurable buttons to move items to specific lists
  - Buttons use target list's icon and color

#### Related Items
- Displayed in expanded card view
- Clickable to navigate to the related item
- Shows which list the related item belongs to
- Auto-expands target item on navigation
- Temporary highlight effect on navigated item

### 4. Sorting & Reordering

#### Sort Modes (per list)
- **Manual** - User-defined order, maintained through reordering
- **Date Ascending** - Oldest due date first
- **Date Descending** - Newest due date first
- **Title** - Alphabetical by item title

#### Manual Reordering
- Drag-and-drop items to reorder
- Long-press to initiate drag (delayed drag start)
- Visual feedback during drag (proxy decorator)
- Automatically switches list to Manual sort mode when reordered
- Works with both mouse and touch gestures

### 5. List Customization

#### Settings Dialog (per list)
- **Icon selection** - Choose from predefined icon set
- **Color selection** - Choose from predefined color palette
- **Swipe left action** - Select target list
- **Swipe right action** - Select target list
- **Card icons** - Select which action buttons to show (max 5)

#### Visual Consistency
- List icon appears in: drawer menu, app bar title, card action buttons
- List color used for: borders, highlights, swipe action backgrounds

### 6. Theme Support
- **Light/Dark mode toggle**
- Theme affects:
  - Card backgrounds
  - Text colors
  - HTML content rendering
  - Icon colors
  - Drawer appearance
  - Table styles in HTML content

### 7. Data Management

#### Current Implementation
- In-memory data structure
- JSON serialization/deserialization for:
  - Items with all properties
  - List configurations
  - Item-to-list mappings
- Placeholder `syncWithApi()` method
- Data sanitization on load and config changes:
  - Remove references to deleted lists
  - Remove references to deleted items
  - Clean up orphaned data

#### Data Validation
- Ensures swipe actions reference valid lists
- Ensures button actions reference valid lists
- Ensures card icons reference valid lists
- Ensures related item IDs reference existing items

### 8. Known Issues & Hardcoded Values
- Due date calculation uses hardcoded "today" date (May 22, 2025) - lib/status_card.dart:269
- All state management in root widget (_MyAppState)
- No data persistence (resets on app restart)
- Sample data hardcoded in Data.initialize()

## Future Requirements

### 9. CRUD Operations (Planned)

#### Item Management
- **Create new items** - Form/dialog to add items to a list
- **Edit existing items** - Modify title, subtitle, HTML, due date, related items
- **Delete items** - Remove items with confirmation
- **Bulk operations** - Select multiple items for batch actions

#### List Management
- **Create new lists** - Add custom lists with configuration
- **Edit lists** - Modify existing list properties
- **Delete lists** - Remove lists (with item migration/deletion handling)
- **Reorder lists** - Change list order in drawer

### 10. Search & Filtering (Planned)
- **Search items** - By title, subtitle, content
- **Filter by list** - Show items from specific lists
- **Filter by date range** - Items due within a timeframe
- **Filter by related items** - Items connected to a specific item
- **Filter by status** - Items matching specific status values
- **Saved filters** - Reusable filter configurations

### 11. Data Persistence (Planned)

#### Local Storage
- Persist data between app sessions
- Options: SQLite, Hive, or similar
- Maintain data integrity across app updates
- Migration strategy for schema changes

#### Remote Sync
- Bi-directional sync with backend API
- Conflict resolution strategy
- Offline-first capability
- Sync status indicators
- Handle network failures gracefully

#### Data Flow
- Local changes saved immediately
- Background sync to remote
- Pull latest from remote on startup
- Merge strategies for conflicts

## Architecture Requirements

### Design Goals
Based on identified pain points, the refactored architecture must:

1. **Maintainability**
   - Clear separation of concerns
   - Well-documented code structure
   - Consistent naming conventions
   - Easy to understand control flow

2. **Testability**
   - Business logic isolated from UI
   - Mockable dependencies
   - Unit tests for core logic
   - Widget tests for UI components
   - Integration tests for data flow

3. **Extensibility**
   - Easy to add new features
   - Minimal changes required for new list types
   - Plugin architecture for custom actions
   - Configurable without code changes

4. **Reusability**
   - Package can be used in different apps
   - Configurable for different use cases
   - No hardcoded business logic
   - Clear public API

### Recommended Patterns

#### State Management
- Consider: Riverpod, Bloc, Provider, or GetX
- Separate UI state from business state
- Reactive updates for data changes

#### Data Layer
- Repository pattern for data access
- Abstract data sources (local/remote)
- Data models separate from domain models
- Type-safe data operations

#### Business Logic
- Use cases/interactors for complex operations
- Domain models for core entities
- Validation logic separate from UI
- Error handling with typed failures

#### Presentation Layer
- View models or controllers for UI state
- Widgets focused on rendering
- Minimal business logic in widgets
- Reusable UI components

## Non-Functional Requirements

### Performance
- Smooth 60fps scrolling with 100+ items
- Animations complete within 300ms
- Responsive to user input (<100ms)
- Efficient memory usage

### Accessibility
- Screen reader support
- Keyboard navigation
- Sufficient color contrast
- Adjustable text sizes

### Platform Support
- iOS, Android, Web, Desktop (Windows, macOS, Linux)
- Responsive layouts for different screen sizes
- Platform-appropriate UI patterns

### Error Handling
- Graceful degradation on errors
- User-friendly error messages
- Recovery mechanisms for common failures
- Logging for debugging

## Technical Constraints

- Flutter 3.x
- Dart 3.x
- Must support null safety
- Compatible with latest Flutter stable channel

## Success Criteria

A successful refactor will:
1. Maintain all current functionality without regression
2. Make it easy to add CRUD operations for items and lists
3. Enable search/filtering implementation
4. Support local + remote persistence
5. Have clear separation between UI, business logic, and data
6. Include comprehensive tests
7. Be documented for other developers to use
8. Reduce coupling between components
