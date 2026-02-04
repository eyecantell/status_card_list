# Integrating status_card_list into contractmatch

This guide is for the Claude instance building the contractmatch Flutter frontend (Phase 3). The status_card_list engine has been refactored into a generic, pluggable card list system. The contractmatch frontend is a thin wrapper that configures the engine with an `HttpDataSource` pointing at the Cloudflare Worker API and custom card builders for contract notice rendering.

**Engine location**: `/mounted/dev/status_card_list/` (used as a package dependency, not forked)
**Consumer location**: `/mounted/dev/contractmatch/frontend/`

---

## Architecture Overview

```
contractmatch/frontend/
├── lib/
│   ├── main.dart                    # Initialize HttpDataSource, provide via ProviderScope
│   ├── data/
│   │   └── contractmatch_mapper.dart  # HttpResponseMapper — maps Worker JSON to engine models
│   ├── widgets/
│   │   └── card_builders.dart       # CardListConfig — custom collapsed/expanded card rendering
│   └── config/
│       └── env.dart                 # API_URL from environment
└── pubspec.yaml                     # depends on status_card_list (path: ../status_card_list)
```

The frontend has **no state management of its own**. The engine's Riverpod providers handle everything. The frontend provides:
1. An `HttpDataSource` (with a `ContractMatchMapper`) pointing at the Worker API
2. A `CardListConfig` with custom builder callbacks for contract notice cards
3. That's it.

---

## Step 1: main.dart — DataSource Initialization

The engine expects a `CardListDataSource` injected into `dataSourceProvider` via `ProviderScope.overrides`. For contractmatch, use the engine's built-in `HttpDataSource` class.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:status_card_list/data_source/http_data_source.dart';
import 'package:status_card_list/providers/data_source_provider.dart';
import 'package:status_card_list/providers/theme_provider.dart';
import 'package:status_card_list/screens/home_screen.dart';
import 'data/contractmatch_mapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // API_URL from env: https://api.contractmatch.pneuma.solutions
  // or http://localhost:8787 for local dev
  const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8787/api');

  final dataSource = HttpDataSource(
    baseUrl: apiUrl,
    mapper: ContractMatchMapper(),
    defaultListId: 'pneuma-llc-review',  // From Worker seed data
    // headersBuilder not needed — Cloudflare Access handles auth via cookies
  );
  await dataSource.initialize();

  runApp(
    ProviderScope(
      overrides: [
        dataSourceProvider.overrideWithValue(dataSource),
      ],
      child: const ContractMatchApp(),
    ),
  );
}

class ContractMatchApp extends ConsumerWidget {
  const ContractMatchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'ContractMatch',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const HomeScreen(), // optionally pass cardListConfig: CardListConfig(...)
    );
  }
}
```

### Key points:
- `defaultListId` must match the Review list's `id` column from the D1 `lists` table (`'pneuma-llc-review'` per seed.sql)
- `headersBuilder` is optional — Cloudflare Access uses cookies, not bearer tokens, for user-facing endpoints
- `HttpDataSource.initialize()` is a no-op for HTTP (stateless), but call it for interface compliance

---

## Step 2: ContractMatchMapper — Field Mapping

This is the core integration piece. The engine's `HttpDataSource` calls Worker endpoints and passes raw JSON to your mapper. The mapper converts Worker response shapes into engine model objects.

### Worker API ↔ Engine Endpoint Mapping

The engine's `HttpDataSource` calls these paths (hardcoded in the engine):

| Engine method | HTTP call | Worker endpoint |
|---|---|---|
| `loadItems(listId, sortMode, limit, offset)` | `GET {baseUrl}/notices?list_id=X&sort=Y&limit=N&offset=N` | `GET /api/notices?list_id=X&sort=Y&limit=N&offset=N&company_id=Z` |
| `loadItemDetail(itemId)` | `GET {baseUrl}/notices/{itemId}` | `GET /api/notices/:notice_id?company_id=Z` |
| `moveItem(itemId, _, targetListId)` | `PUT {baseUrl}/notices/{itemId}/list` body: `{"list_id":"X"}` | `PUT /api/notices/:notice_id/list?company_id=Z` |
| `updateItemPosition(_, itemId, pos)` | `PUT {baseUrl}/notices/{itemId}/position` body: `{"position":N}` | `PUT /api/notices/:notice_id/position?company_id=Z` |
| `loadLists()` | `GET {baseUrl}/lists` | `GET /api/lists?company_id=Z` |
| `updateList(listId, config)` | `PUT {baseUrl}/lists/{listId}` | `PUT /api/lists/:id` |
| `getStatus()` | `GET {baseUrl}/status` | `GET /api/status?company_id=Z` |
| `findListContainingItem(itemId)` | `GET {baseUrl}/notices/{itemId}` → extracts `list_id` | same as loadItemDetail |

**Important**: The engine's `HttpDataSource` does NOT append `?company_id=`. For MVP (single company), the Worker defaults to `DEFAULT_COMPANY_ID` from wrangler.toml. For multi-company later, you'll extend to `MultiContextHttpDataSource` (see Step 4).

### HttpResponseMapper interface

You must implement all 4 methods:

```dart
abstract class HttpResponseMapper {
  ItemsPage parseItemsPage(Map<String, dynamic> json);
  Item parseItemDetail(Map<String, dynamic> json);
  List<ListConfig> parseListConfigs(List<dynamic> json);
  Map<String, dynamic> parseStatus(Map<String, dynamic> json);
}
```

### Field mapping: Worker notice → engine Item

| Worker JSON field | Item field | Notes |
|---|---|---|
| `notice_id` | `id` | |
| `title` | `title` | |
| derived: `"{score}% — {capability}"` | `subtitle` | e.g. `"87% — Cybersecurity"` |
| `html_content` | `html` | **null** from list endpoint, populated from detail endpoint |
| `response_deadline` | `dueDate` | Parse ISO 8601 string to `DateTime?` |
| `status` (`"active"` / `"expired"`) | `status` | Computed by Worker from response_deadline |
| (none for list endpoint) | `relatedItemIds` | Empty list — contractmatch has no related items |
| `best_similarity`, `best_capability_name`, `matched_capabilities`, `set_aside`, `naics_codes`, `place_of_performance`, `clearance_required`, `notice_url`, `short_description` | `extra` | All domain-specific fields go in extra map |

### Field mapping: Worker list → engine ListConfig

| Worker JSON field | ListConfig field | Notes |
|---|---|---|
| `id` | `uuid` | e.g. `"pneuma-llc-review"` |
| `name` | `name` | e.g. `"Review"` |
| `icon` | `iconName` | String key, see icon map below |
| `color` | `colorValue` | Hex string `"#2196F3"` → int `0xFF2196F3` |
| `sort_mode` | `sortMode` | String → `SortMode` enum |
| (derived from list relationships) | `swipeActions` | See below |
| (derived from list relationships) | `buttons` | See below |
| (derived) | `cardIcons` | See below |

### Implementation

```dart
import 'package:status_card_list/data_source/http_data_source.dart';
import 'package:status_card_list/data_source/items_page.dart';
import 'package:status_card_list/models/item.dart';
import 'package:status_card_list/models/list_config.dart';
import 'package:status_card_list/models/sort_mode.dart';

class ContractMatchMapper implements HttpResponseMapper {
  @override
  ItemsPage parseItemsPage(Map<String, dynamic> json) {
    final notices = json['notices'] as List<dynamic>;
    final items = notices.map((n) => _noticeToItem(n as Map<String, dynamic>, includeHtml: false)).toList();
    return ItemsPage(
      items: items,
      totalCount: json['total'] as int,
      hasMore: ((json['offset'] as int) + (json['limit'] as int)) < (json['total'] as int),
      offset: json['offset'] as int,
    );
  }

  @override
  Item parseItemDetail(Map<String, dynamic> json) {
    return _noticeToItem(json, includeHtml: true);
  }

  @override
  List<ListConfig> parseListConfigs(List<dynamic> json) {
    // Worker returns lists ordered by position.
    // We need to figure out list relationships for swipe/button actions.
    // Convention from seed data: lists are [Review, Saved, Trash] per company.
    final lists = json.cast<Map<String, dynamic>>();

    // Build a lookup: find review/saved/trash by examining names or positions
    String? reviewId, savedId, trashId;
    for (final l in lists) {
      final name = (l['name'] as String).toLowerCase();
      if (name == 'review') reviewId = l['id'] as String;
      if (name == 'saved') savedId = l['id'] as String;
      if (name == 'trash') trashId = l['id'] as String;
    }

    return lists.map((l) {
      final id = l['id'] as String;
      final name = l['name'] as String;

      // Determine swipe actions and button icons based on list role
      Map<String, String> swipeActions;
      Map<String, String> buttons;
      List<CardIconEntry> cardIcons;
      String iconName;

      if (id == reviewId) {
        // Review: swipe right → Saved, swipe left → Trash
        swipeActions = {
          if (savedId != null) 'right': savedId,
          if (trashId != null) 'left': trashId,
        };
        buttons = {
          if (savedId != null) 'check_circle': savedId,
          if (trashId != null) 'delete': trashId,
        };
        cardIcons = [
          if (savedId != null) CardIconEntry(iconName: 'check_circle', targetListId: savedId),
          if (trashId != null) CardIconEntry(iconName: 'delete', targetListId: trashId),
        ];
        iconName = 'inbox';
      } else if (id == savedId) {
        // Saved: swipe left → Trash, swipe right → Review
        swipeActions = {
          if (reviewId != null) 'right': reviewId,
          if (trashId != null) 'left': trashId,
        };
        buttons = {
          if (reviewId != null) 'refresh': reviewId,
          if (trashId != null) 'delete': trashId,
        };
        cardIcons = [
          if (reviewId != null) CardIconEntry(iconName: 'refresh', targetListId: reviewId),
          if (trashId != null) CardIconEntry(iconName: 'delete', targetListId: trashId),
        ];
        iconName = 'bookmark';
      } else if (id == trashId) {
        // Trash: swipe right → Review
        swipeActions = {
          if (reviewId != null) 'right': reviewId,
        };
        buttons = {
          if (reviewId != null) 'refresh': reviewId,
        };
        cardIcons = [
          if (reviewId != null) CardIconEntry(iconName: 'refresh', targetListId: reviewId),
        ];
        iconName = 'delete';
      } else {
        swipeActions = {};
        buttons = {};
        cardIcons = [];
        iconName = 'list';
      }

      return ListConfig(
        uuid: id,
        name: name,
        swipeActions: swipeActions,
        buttons: buttons,
        dueDateLabel: 'Response Deadline',
        sortMode: _parseSortMode(l['sort_mode'] as String? ?? 'similarityDescending'),
        iconName: iconName,
        colorValue: _parseColor(l['color'] as String? ?? '#2196F3'),
        cardIcons: cardIcons,
      );
    }).toList();
  }

  @override
  Map<String, dynamic> parseStatus(Map<String, dynamic> json) {
    // Pass through — engine uses json['counts'] as Map<String, int>
    return {
      'counts': (json['counts'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)) ?? {},
    };
  }

  // --- Helpers ---

  Item _noticeToItem(Map<String, dynamic> n, {required bool includeHtml}) {
    final bestSimilarity = (n['best_similarity'] as num?)?.toDouble();
    final bestCapability = n['best_capability_name'] as String?;

    // Build subtitle: "87% — Cybersecurity" or just the short description
    String subtitle;
    if (bestSimilarity != null && bestCapability != null) {
      subtitle = '${(bestSimilarity * 100).toStringAsFixed(0)}% — $bestCapability';
    } else {
      subtitle = n['short_description'] as String? ?? '';
    }

    return Item(
      id: n['notice_id'] as String,
      title: n['title'] as String,
      subtitle: subtitle,
      html: includeHtml ? n['html_content'] as String? : null,
      dueDate: n['response_deadline'] != null
          ? DateTime.tryParse(n['response_deadline'] as String)
          : null,
      status: n['status'] as String? ?? 'active',
      relatedItemIds: const [],
      extra: {
        'best_similarity': bestSimilarity,
        'best_capability_name': bestCapability,
        'matched_capabilities': n['matched_capabilities'],
        'short_description': n['short_description'],
        'set_aside': n['set_aside'],
        'naics_codes': n['naics_codes'],
        'place_of_performance': n['place_of_performance'],
        'clearance_required': n['clearance_required'],
        'notice_url': n['notice_url'],
        'list_id': n['list_id'],
      },
    );
  }

  SortMode _parseSortMode(String value) {
    return SortMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => SortMode.similarityDescending,
    );
  }

  int _parseColor(String hex) {
    String h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    return int.parse('0x$h');
  }
}
```

---

## Step 3: Card Builders — Custom Rendering

The engine renders cards with default builders (title, status, due date, html). Contractmatch overrides these to show match scores and capability details.

`HomeScreen` accepts an optional `CardListConfig?` parameter. Pass it to customize card rendering:

### Collapsed card content

Default shows: title, status, due date. Contractmatch wants: title, best match line, response deadline.

The default rendering actually works reasonably well since:
- `Item.title` = notice title
- `Item.subtitle` = `"87% — Cybersecurity"` (set in mapper)
- `Item.dueDate` = response deadline
- `Item.status` = `"active"` / `"expired"`

So you may not need custom builders at all for MVP. The default card shows title, subtitle, status, and due date — which is exactly what contractmatch needs in collapsed view.

### Expanded card content

The default expanded view renders `item.html` via `flutter_html`. The Worker's `html_content` field is pre-rendered HTML containing the full notice detail (capabilities, description, skills, NAICS, etc.). This should work out of the box.

If you want to add a capability match table above the HTML (structured data from `item.extra['matched_capabilities']`), use `expandedBuilder`:

```dart
CardListConfig(
  expandedBuilder: (context, item, isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final capabilities = item.extra['matched_capabilities'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Matched capabilities table
        if (capabilities.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Matched Capabilities',
              style: Theme.of(context).textTheme.titleSmall),
          ),
          ...capabilities.map((cap) {
            final c = cap as Map<String, dynamic>;
            final score = ((c['similarity'] as num) * 100).toStringAsFixed(0);
            return ListTile(
              dense: true,
              title: Text('${c['capability_name']} — $score%'),
              subtitle: Text(c['matched_area_name'] ?? ''),
            );
          }),
          const Divider(),
        ],
        // Full HTML content
        if (item.html != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Html(data: item.html!),
          ),
      ],
    );
  },
)
```

### Trailing builder (optional)

Show an "Expired" badge on saved notices:

```dart
CardListConfig(
  trailingBuilder: (context, item) {
    if (item.status == 'expired') {
      return Chip(
        label: const Text('Expired'),
        backgroundColor: Colors.red.shade100,
        labelStyle: TextStyle(color: Colors.red.shade800, fontSize: 12),
      );
    }
    return const SizedBox.shrink();
  },
)
```

---

## Step 4: Multi-Company Support (Future)

The engine supports multi-context via `MultiContextDataSource`. For contractmatch, "context" = company.

The current `HttpDataSource` doesn't append `?company_id=` to requests. For multi-company, create a subclass:

```dart
class ContractMatchDataSource extends HttpDataSource implements MultiContextDataSource {
  String _currentCompanyId;
  List<DataContext> _companies = [];

  ContractMatchDataSource({
    required super.baseUrl,
    required super.mapper,
    required String initialCompanyId,
    super.headersBuilder,
    super.client,
  }) : _currentCompanyId = initialCompanyId,
       super(defaultListId: '$initialCompanyId-review');

  // Override _headers or baseUrl to append company_id
  // Simplest approach: override each method to append ?company_id=

  @override
  Future<List<DataContext>> loadContexts() async {
    // GET {baseUrl}/companies
    final uri = Uri.parse('$baseUrl/companies');
    final resp = await _client.get(uri, headers: _headers);
    final json = jsonDecode(resp.body) as List;
    _companies = json.map((c) => DataContext(
      id: c['id'] as String,
      name: c['name'] as String,
    )).toList();
    return _companies;
  }

  @override
  Future<void> switchContext(String contextId) async {
    _currentCompanyId = contextId;
    // Engine will invalidate listConfigsProvider and itemsProvider
  }

  @override
  DataContext get currentContext =>
    _companies.firstWhere((c) => c.id == _currentCompanyId);

  @override
  String get defaultListId => '$_currentCompanyId-review';
}
```

When this is used, the drawer menu automatically shows a company dropdown if `loadContexts()` returns more than one company.

**For MVP**: Skip this. Use plain `HttpDataSource` with `DEFAULT_COMPANY_ID` handled server-side.

---

## Worker API Response Shapes (Reference)

These are the exact JSON shapes the mapper will receive. From the Worker API spec:

### GET /api/notices?list_id=X&sort=Y&limit=N&offset=N

```json
{
  "notices": [
    {
      "notice_id": "sam-123",
      "title": "SOC Operations Support",
      "short_description": "24/7 SOC monitoring and incident response",
      "response_deadline": "2026-03-15",
      "status": "active",
      "best_similarity": 0.87,
      "best_capability_name": "Cybersecurity",
      "matched_capabilities": [
        {
          "capability_id": "uuid-1",
          "capability_name": "Cybersecurity",
          "similarity": 0.87,
          "matched_area_name": "SOC Operations",
          "matched_area_description": "24/7 Security Operations Center monitoring..."
        }
      ],
      "list_id": "pneuma-llc-review",
      "position": 0
    }
  ],
  "total": 42,
  "limit": 50,
  "offset": 0
}
```

Note: `html_content` is **omitted** from list responses for performance.

### GET /api/notices/:notice_id

Same fields as above, **plus** `html_content`:

```json
{
  "notice_id": "sam-123",
  "title": "SOC Operations Support",
  "html_content": "<h2>Description</h2><p>...</p>",
  ...all other fields...
}
```

### GET /api/lists?company_id=X

```json
[
  {
    "id": "pneuma-llc-review",
    "company_id": "pneuma-llc",
    "name": "Review",
    "icon": "inbox",
    "color": "#2196F3",
    "sort_mode": "similarityDescending",
    "position": 0,
    "is_default_inbox": 1
  },
  {
    "id": "pneuma-llc-saved",
    "name": "Saved",
    "icon": "bookmark",
    "color": "#4CAF50",
    "sort_mode": "similarityDescending",
    "position": 1,
    "is_default_inbox": 0
  },
  {
    "id": "pneuma-llc-trash",
    "name": "Trash",
    "icon": "delete",
    "color": "#F44336",
    "sort_mode": "newest",
    "position": 2,
    "is_default_inbox": 0
  }
]
```

### GET /api/status?company_id=X

```json
{
  "company_id": "pneuma-llc",
  "last_sync": "2026-02-02T12:00:00Z",
  "counts": {
    "pneuma-llc-review": 42,
    "pneuma-llc-saved": 8,
    "pneuma-llc-trash": 15
  },
  "total_notices": 65
}
```

---

## Engine Sort Modes ↔ Worker Sort Values

The engine sends `sort` query parameter as the enum name. These must match exactly what the Worker expects:

| Engine SortMode | Query string | Worker SQL ORDER BY |
|---|---|---|
| `similarityDescending` | `sort=similarityDescending` | `best_similarity DESC` |
| `deadlineSoonest` | `sort=deadlineSoonest` | `response_deadline ASC NULLS LAST` |
| `newest` | `sort=newest` | `synced_at DESC` |
| `title` | `sort=title` | `title COLLATE NOCASE ASC` |
| `manual` | `sort=manual` | `la.position ASC` (from list_assignments) |
| `dateAscending` | `sort=dateAscending` | `response_deadline ASC NULLS LAST` |
| `dateDescending` | `sort=dateDescending` | `response_deadline DESC NULLS LAST` |

The Worker must handle all 7 sort values. For contractmatch, the useful ones are `similarityDescending` (default), `deadlineSoonest`, `newest`, `title`, and `manual`.

---

## Engine Icon Names (for ListConfig)

The engine maps string icon names to `IconData` via two maps in `lib/utils/constants.dart`:

**Card action icons** (for buttons and cardIcons on cards):
- `check_circle` → Icons.check_circle
- `delete` → Icons.delete
- `refresh` → Icons.refresh
- `delete_forever` → Icons.delete_forever

**List icons** (for drawer and app bar):
- `inbox` → Icons.inbox (use for Review)
- `bookmark` → Icons.bookmark (use for Saved)
- `delete` → Icons.delete (use for Trash)
- `list`, `rate_review`, `folder`, `star`, `archive` also available

The Worker's `lists.icon` column should store these exact string keys.

---

## Expired Notice Handling in the Engine

The Worker computes `status: "active" | "expired"` dynamically based on `response_deadline < date('now')`.

- **Review list**: Worker excludes expired notices from `GET /api/notices?list_id=review` responses
- **Saved/Trash lists**: Worker returns expired notices with `status: "expired"`
- **Engine display**: `Item.status` shows in the card's status area. Use `trailingBuilder` to add an "Expired" badge if desired
- **Engine sorting**: `Item.isOverdue` returns `true` when `dueDate` is past — available for custom builders

---

## What the Frontend Does NOT Need to Do

The engine handles all of this:
- Swipe gesture detection and animation
- Drag-to-reorder (ReorderableListView)
- Card expand/collapse with animation
- On-demand HTML loading (shows spinner, calls `loadItemDetail`, re-renders)
- Sort mode dropdown in app bar
- List selector dropdown in app bar (PopupMenuButton, switches lists without opening drawer)
- Drawer menu with list selection and item counts
- Theme switching (light/dark) with tuned scaffold/card contrast
- Item cache for cross-list lookups
- Scroll-to and highlight animation for navigation

The frontend just provides data (mapper) and optional visual customization (builders).

---

## Checklist

- [ ] Create `contractmatch/frontend/` Flutter project
- [ ] Add `status_card_list` as path dependency in pubspec.yaml
- [ ] Implement `ContractMatchMapper` (the only required code)
- [ ] Wire up `main.dart` with `HttpDataSource` + mapper
- [ ] Verify against local Worker (`npx wrangler dev` on port 8787)
- [ ] (Optional) Add `CardListConfig` with custom `expandedBuilder` for capability table
- [ ] (Optional) Add `trailingBuilder` for "Expired" badge
- [ ] Test: notices load, swiping moves between lists, expanding loads HTML detail, sort modes work
- [ ] Build for web: `flutter build web`
- [ ] Deploy to Cloudflare Pages
