# ContractMatch Demo Website Plan

## Overview

Build a demo website at `contractmatch.pneuma.solutions` that displays contract notice matches, letting users triage notices into lists (Review → Saved / Trash). Multi-company support from the start (Pneuma LLC as first company, more later). Each company gets its own set of lists.

## Architecture

```
┌─────────────────────┐     ┌──────────────────────────────────┐
│  K8s Cluster         │     │  Cloudflare                      │
│                      │     │                                  │
│  PostgreSQL          │     │  Cloudflare Access (email OTP)   │
│  (match_notifications│     │         │                        │
│   notice_metadata    │────▶│  Pages (Flutter Web)             │
│   notice summaries)  │push │         │ API calls              │
│                      │     │  Worker (Hono + D1)              │
│  sync_to_cloudflare  │     │         │                        │
│  (cronjob)           │     │  D1 (notices, lists, assignments)│
└─────────────────────┘     └──────────────────────────────────┘
```

**Stack** (mirrors `/mounted/dev/pneuma_llc/` patterns):
- **Worker**: Hono 4.x + TypeScript + D1 (SQLite)
- **Frontend**: Flutter Web on Cloudflare Pages (status_card_list as generic engine)
- **Auth**: Cloudflare Access (Zero Trust, email OTP) + Access JWT verification in Worker
- **Sync**: Python script on k8s pushes matches to Worker API

**Project location**: `/mounted/dev/contractmatch/` (Worker API + thin Flutter frontend)
**Card engine**: `/mounted/dev/status_card_list/` (improved in place, not forked)

---

## Design Requirements

### Card Display

**Collapsed card shows:**
- Notice title
- Best match: percentage + capability name (e.g. "87% — Cybersecurity")
- Response deadline date

**Expanded card** (fetched on demand via `GET /api/notices/:id` — D1 latency ~50ms, negligible):
1. **Matched capabilities** — ranked list by similarity score, each entry:
   - Capability name + similarity percentage
   - Matched requirement area name
   - Matched requirement area description
2. **Full notice content:**
   - Short description, work description
   - Skills & tools, domains
   - NAICS codes, set-aside programs
   - Clearance requirement, place of performance
   - Attachment summaries (when available)

### Sort Modes

Default sort: **best match first** (highest similarity descending).

Available sort modes per list:
- `similarityDescending` — best match first **(default for Review)**
- `deadlineSoonest` — response deadline ascending
- `newest` — most recently synced first
- `title` — alphabetical
- `manual` — user drag-to-reorder

### Lists & Workflow

Three default lists per company, simple triage flow:

| List | Purpose | Default Sort |
|------|---------|-------------|
| **Review** (blue, inbox) | New matches land here | similarityDescending |
| **Saved** (green) | Worth pursuing | similarityDescending |
| **Trash** (red) | Not relevant | newest |

- Swipe right → Saved
- Swipe left → Trash

### Multi-Company Model

- Users can have multiple companies (profiles)
- Each company has its own set of lists (Review/Saved/Trash)
- Same SAM.gov notice can match multiple companies with different capabilities/scores
- Switching companies switches the entire list view
- MVP: Pneuma LLC only, but schema and API support multi-company from day one

### Expired Notice Handling

- **Sync time**: Don't push notices that are already expired
- **Review list**: API filters out notices that expired between sync and viewing
- **Saved list**: Expired notices remain but display an "Expired" badge
- **Trash list**: No special handling

### Match Threshold

`NoticeMatcher.get_top_matches()` uses a **global** similarity threshold (default 0.7). Per-capability thresholds (`company_capabilities.similarity_threshold`) only apply in `find_companies_for_notice()` (reverse direction). For the sync script, the global 0.7 is fine for the demo. To use per-capability thresholds later, modify `find_matches_for_company()` SQL to use `COALESCE(c.similarity_threshold, :similarity_threshold)`.

### Future: Single vs Combined Capability View

The data model stores all matched capabilities per notice. Frontend can later support filtering to a single capability's matches. No schema changes needed.

---

## Phases

| # | Phase | Scope |
|---|-------|-------|
| 1 | Worker API + D1 | Hono API, D1 schema, sync endpoint, list CRUD. Deploy Worker at end. |
| 2 | Sync Script | Python script in samscrape to push matches to deployed Worker |
| 3 | Flutter Frontend | Evolve status_card_list into generic engine; contractmatch configures it |
| 4 | Deployment & Auth | Cloudflare Pages, Access, DNS, CI/CD |

---

## Phase 1: Worker API + D1

### Project Scaffold

```
/mounted/dev/contractmatch/
├── workers-api/
│   ├── src/
│   │   ├── index.ts          # Hono app, routes, CORS, auth middleware
│   │   └── types.ts          # TypeScript interfaces
│   ├── schema.sql            # D1 schema
│   ├── seed.sql              # Default lists + sample notices
│   ├── wrangler.toml
│   ├── tsconfig.json
│   └── package.json
├── frontend/                  # (Phase 3 — thin app configuring status_card_list)
├── CLAUDE.md
└── README.md
```

### D1 Schema

```sql
-- Companies
CREATE TABLE IF NOT EXISTS companies (
  id TEXT PRIMARY KEY,              -- e.g. 'pneuma-llc'
  name TEXT NOT NULL,               -- e.g. 'Pneuma LLC'
  created_at TEXT DEFAULT (datetime('now'))
);

-- Notices synced from k8s matching pipeline
-- Composite PK: same notice can match multiple companies with different capabilities
CREATE TABLE IF NOT EXISTS notices (
  notice_id TEXT NOT NULL,
  company_id TEXT NOT NULL REFERENCES companies(id),
  title TEXT NOT NULL,
  short_description TEXT,               -- Brief summary for card preview
  response_deadline TEXT,               -- ISO 8601 date; status computed dynamically in queries
  best_similarity REAL NOT NULL,        -- Highest match score across capabilities (0-1)
  best_capability_name TEXT,            -- Name of the highest-scoring capability match
  matched_capabilities TEXT NOT NULL,   -- JSON array (see below)
  html_content TEXT NOT NULL,           -- Pre-rendered HTML for expanded card body
  set_aside TEXT,                       -- JSON array e.g. ["SBA","SDVOSBC"]
  naics_codes TEXT,                     -- JSON array e.g. ["541512"]
  place_of_performance TEXT,            -- JSON array e.g. ["VA","MD"]
  clearance_required TEXT,              -- e.g. "SECRET" or null
  notice_url TEXT,                      -- From contract_notice.browser_link
  synced_at TEXT DEFAULT (datetime('now')),
  created_at TEXT DEFAULT (datetime('now')),
  PRIMARY KEY (notice_id, company_id)
);
CREATE INDEX IF NOT EXISTS idx_notices_company ON notices(company_id);
CREATE INDEX IF NOT EXISTS idx_notices_similarity ON notices(company_id, best_similarity DESC);
CREATE INDEX IF NOT EXISTS idx_notices_deadline ON notices(company_id, response_deadline);
CREATE INDEX IF NOT EXISTS idx_notices_title ON notices(company_id, title COLLATE NOCASE);

-- User list definitions — per company
CREATE TABLE IF NOT EXISTS lists (
  id TEXT PRIMARY KEY,                  -- e.g. 'pneuma-llc-review'
  company_id TEXT NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  icon TEXT DEFAULT 'list',
  color TEXT DEFAULT '#2196F3',
  sort_mode TEXT DEFAULT 'similarityDescending',
  position INTEGER DEFAULT 0,
  is_default_inbox INTEGER DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_lists_company ON lists(company_id);

-- Which list each notice belongs to + manual ordering
CREATE TABLE IF NOT EXISTS list_assignments (
  notice_id TEXT NOT NULL,
  company_id TEXT NOT NULL,
  list_id TEXT NOT NULL REFERENCES lists(id),
  position INTEGER DEFAULT 0,
  assigned_at TEXT DEFAULT (datetime('now')),
  PRIMARY KEY (notice_id, company_id),
  FOREIGN KEY (notice_id, company_id) REFERENCES notices(notice_id, company_id)
);
CREATE INDEX IF NOT EXISTS idx_assignments_list ON list_assignments(list_id);
CREATE INDEX IF NOT EXISTS idx_assignments_list_position ON list_assignments(list_id, position);

-- Sync tracking
CREATE TABLE IF NOT EXISTS sync_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  company_id TEXT REFERENCES companies(id),
  notices_inserted INTEGER DEFAULT 0,
  notices_updated INTEGER DEFAULT 0,
  synced_at TEXT DEFAULT (datetime('now'))
);
```

**matched_capabilities JSON shape** (sorted by similarity descending):
```json
[
  {
    "capability_id": "uuid-1",
    "capability_name": "Cybersecurity",
    "similarity": 0.87,
    "matched_area_name": "SOC Operations",
    "matched_area_description": "24/7 Security Operations Center monitoring..."
  },
  {
    "capability_id": "uuid-2",
    "capability_name": "Cloud Migration",
    "similarity": 0.74,
    "matched_area_name": "AWS Infrastructure",
    "matched_area_description": "Migration of on-premise systems to AWS GovCloud..."
  }
]
```

**Seed data** includes:
- 1 company (Pneuma LLC)
- 3 lists for that company (Review, Saved, Trash)
- 3-5 sample notices with realistic matched_capabilities and html_content

### API Endpoints

**Bindings:**
```typescript
type Bindings = {
  DB: D1Database;
  SYNC_API_KEY: string;
  DEFAULT_COMPANY_ID: string;  // 'pneuma-llc' — avoids hardcoding
};
```

**CORS config:**
```typescript
cors({
  origin: [
    'https://contractmatch.pneuma.solutions',
    'https://contractmatch.pages.dev',
    'http://localhost:8080',
  ],
  allowMethods: ['GET', 'PUT', 'POST', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400,
})
```

All user-facing endpoints accept `?company_id=` query param (defaults to `DEFAULT_COMPANY_ID`).

**Routes:**

#### `GET /api/notices?list_id=review&sort=similarityDescending&limit=50&offset=0&company_id=pneuma-llc`
Returns notices for a list. Omits `html_content` for performance.
```typescript
// Response
{
  notices: [
    {
      notice_id: string,
      title: string,
      short_description: string | null,
      response_deadline: string | null,
      status: "active" | "expired",       // computed: deadline < now → expired
      best_similarity: number,
      best_capability_name: string | null,
      matched_capabilities: CapabilityMatch[],
      list_id: string,
      position: number,
    }
  ],
  total: number,
  limit: number,
  offset: number
}
```
Sort values: `similarityDescending`, `deadlineSoonest`, `newest`, `title`, `manual`

Expired handling: `status` is computed dynamically (`response_deadline < date('now')` → `'expired'`, else `'active'`). For Review list, exclude expired notices from results. For Saved/Trash, return them with `status: 'expired'` for badge display.

#### `GET /api/notices/:notice_id?company_id=pneuma-llc`
Returns full notice including `html_content`. Used when user expands a card.

#### `PUT /api/notices/:notice_id/list?company_id=pneuma-llc`
```typescript
// Request
{ list_id: "pneuma-llc-saved" }
// Response
{ success: true, notice_id: string, list_id: string }
```

#### `PUT /api/notices/:notice_id/position?company_id=pneuma-llc`
```typescript
// Request
{ position: 3 }
// Server logic: shift other cards' positions to make room
// If moving from pos 5 → pos 2: increment positions in [2, 5)
// If moving from pos 2 → pos 5: decrement positions in (2, 5]
```

#### `POST /api/sync`
Auth: `Authorization: Bearer <SYNC_API_KEY>` (machine-to-machine, not Cloudflare Access)
```typescript
// Request — max 50 notices per batch
{
  company_id: string,
  notices: SyncNotice[],
  sync_timestamp: string
}
// Response
{
  inserted: number,
  updated: number,
  errors: { notice_id: string, error: string }[]
}
```
- Upserts via `INSERT ... ON CONFLICT (notice_id, company_id) DO UPDATE SET` (NOT `INSERT OR REPLACE` — that DELETEs first, which cascades and destroys list_assignments)
- Updates all notice fields on conflict (title, similarity, capabilities, html, etc.) but does NOT touch list_assignments
- New notices not in list_assignments → assigned to company's default inbox list
- Already-triaged notices keep their list assignment (verified by re-sync test)
- Rejects batches > 50 (sync script chunks)

#### `GET /api/companies`
Returns all companies. For company switcher in frontend.

#### `GET /api/lists?company_id=pneuma-llc`
Returns lists for a company, ordered by position.

#### `PUT /api/lists/:id`
Update list properties (name, icon, color, sort_mode).

#### `GET /api/status?company_id=pneuma-llc`
```typescript
{
  company_id: string,
  last_sync: string | null,
  counts: { [list_id: string]: number },  // e.g. {"pneuma-llc-review": 42, ...}
  total_notices: number
}
```

### Files to Create

1. `workers-api/package.json` — hono, @cloudflare/workers-types, typescript, wrangler
2. `workers-api/tsconfig.json` — match pneuma_llc pattern
3. `workers-api/wrangler.toml` — D1 binding, DEFAULT_COMPANY_ID var
4. `workers-api/schema.sql` — tables above
5. `workers-api/seed.sql` — Pneuma LLC company + 3 lists + 3-5 sample notices
6. `workers-api/src/types.ts` — Company, Notice, ListConfig, CapabilityMatch, SyncNotice interfaces
7. `workers-api/src/index.ts` — Hono app with all routes
8. `CLAUDE.md` — dev commands, deploy instructions

### Verification

```bash
cd /mounted/dev/contractmatch/workers-api
npm install
npx wrangler d1 create contractmatch              # one-time, update wrangler.toml with ID
npx wrangler d1 execute contractmatch --local --file=schema.sql
npx wrangler d1 execute contractmatch --local --file=seed.sql
npx wrangler dev                                    # starts on localhost:8787

# Test endpoints
curl localhost:8787/api/status
curl localhost:8787/api/companies
curl localhost:8787/api/lists
curl "localhost:8787/api/notices?list_id=pneuma-llc-review&limit=10"
curl "localhost:8787/api/notices/sample-1"
curl -X PUT "localhost:8787/api/notices/sample-1/list" \
  -H 'Content-Type: application/json' -d '{"list_id":"pneuma-llc-saved"}'
curl "localhost:8787/api/notices?list_id=pneuma-llc-saved"
curl -X POST localhost:8787/api/sync \
  -H 'Authorization: Bearer test-key' \
  -H 'Content-Type: application/json' \
  -d '{"company_id":"pneuma-llc","notices":[{"notice_id":"new-1","title":"Test","best_similarity":0.85,"best_capability_name":"Cybersecurity","matched_capabilities":"[]","html_content":"<p>test</p>"}],"sync_timestamp":"2026-02-02T00:00:00Z"}'
curl "localhost:8787/api/notices?list_id=pneuma-llc-review"  # new-1 should appear

# Critical test: re-sync must NOT reset list assignments
curl -X PUT "localhost:8787/api/notices/new-1/list" \
  -H 'Content-Type: application/json' -d '{"list_id":"pneuma-llc-saved"}'
curl -X POST localhost:8787/api/sync \
  -H 'Authorization: Bearer test-key' \
  -H 'Content-Type: application/json' \
  -d '{"company_id":"pneuma-llc","notices":[{"notice_id":"new-1","title":"Updated Title","best_similarity":0.90,"best_capability_name":"Cybersecurity","matched_capabilities":"[]","html_content":"<p>updated</p>"}],"sync_timestamp":"2026-02-02T01:00:00Z"}'
curl "localhost:8787/api/notices?list_id=pneuma-llc-saved"   # new-1 must still be in Saved
curl "localhost:8787/api/notices/new-1"                       # title should be "Updated Title"

# Deploy Worker (end of Phase 1)
npx wrangler d1 execute contractmatch --remote --file=schema.sql
npx wrangler d1 execute contractmatch --remote --file=seed.sql
npx wrangler secret put SYNC_API_KEY
npx wrangler deploy
```

---

## Phase 2: Sync Script (outline)

**Location**: `samscrape/scripts/sync_matches_to_cloudflare.py`

**Approach**: Call `NoticeMatcher.get_top_matches(company_id)` which respects per-capability thresholds via `COALESCE(c.similarity_threshold, :default_threshold)`.

**Flow:**
1. Call `get_top_matches(company_id)` — returns deduplicated matches sorted by best similarity
2. Filter out expired notices (response_deadline < today)
3. Enrich each match with notice summary data from disk (via `NoticePersistence.load_notice()`)
4. Pre-render HTML card body (adapted from `samscrape/reporting/build_notice_html.py`)
5. Extract `best_capability_name` from the highest-scoring capability in each match
6. Batch into chunks of 50, POST each to Worker `/api/sync`
7. Log sync results
8. Track last sync timestamp (file on disk) to detect new/changed matches

**Error handling:**
- Retry failed batches with exponential backoff (3 retries)
- Log failures, continue with remaining batches
- Full re-sync mode: `--force` flag ignores last sync timestamp

**Key samscrape files:**
- `samscrape/matching/matcher.py` — `get_top_matches()`, `deduplicate_matches()`
- `samscrape/reporting/build_notice_html.py` — HTML rendering patterns
- `samscrape/summaries/summary.py` — Summary and RequirementArea models
- `samscrape/contract_notices/notice_persistence.py` — `load_notice()` for browser_link etc.

**Deployed as**: k8s cronjob (hourly initially, adjustable)

## Phase 3: Flutter Frontend (outline)

**Depends on**: status_card_list generic engine refactor (planned separately — see Appendix A).

### contractmatch/frontend — Thin Wrapper

Configures the generic status_card_list engine with:
- HTTP API data source pointing to Worker URL
- Card builders that render match percentage + capability name (collapsed) and match details + notice HTML (expanded)
- Environment config (.env.development / .env.production with API_URL)
- Company selector (reads from `GET /api/companies`)
- "Expired" badge rendering for saved notices
- Poll timer for new match detection

## Phase 4: Deployment & Auth (outline)

- Cloudflare Pages project for Flutter web build
- Cloudflare Access policy on contractmatch.pneuma.solutions (email OTP)
- Worker deployed separately (api.contractmatch.pneuma.solutions or similar)
- Access JWT verification middleware in Worker for user-facing endpoints
- Sync endpoint uses SYNC_API_KEY (machine-to-machine, exempt from Access)
- DNS CNAME to Pages
- GitHub Actions CI/CD (mirror pneuma_llc/deploy.yml)

---

## Appendix A: status_card_list Generic Engine Refactor

> **This section is a standalone design document.** Extract to a file and give to Claude in a separate instance working on `/mounted/dev/status_card_list/`.

---

# status_card_list — Generic Engine Refactor

## Goal

Refactor status_card_list from a hardcoded demo app into a **configurable card list engine** that can be consumed by different applications. The first consumer will be a contract match triage app (contractmatch), but the engine should be generic enough for any card-based list workflow.

## Current State

status_card_list is a Flutter app at `/mounted/dev/status_card_list/` with:

### Existing Data Model (`lib/item.dart`)
```dart
class Item {
  String id;
  String title;
  String subtitle;
  String html;          // Rich HTML content for expanded card
  DateTime dueDate;
  String status;        // e.g. "Open", "Awarded", "Expired"
  List<String> relatedItemIds;
}
```

### Existing List Config (`lib/list_config.dart`)
```dart
class ListConfig {
  String uuid;
  String name;
  IconData icon;
  Color color;
  Map<String, String> swipeActions;   // direction → target list UUID
  Map<String, String> buttons;        // button label → target list UUID
  List<MapEntry> cardIcons;           // icons shown on collapsed card
  String dueDateLabel;
  SortMode sortMode;                  // dateAscending, dateDescending, title, manual
}
```

### Existing Features
- Expandable cards with HTML content (via `flutter_html` package)
- Multiple lists with swipe-to-move between them
- Drag-to-reorder within a list
- Related item navigation with highlight animation
- Light/dark theme switching
- Drawer menu for list selection and list settings dialog
- Default lists: Review (blue), Saved (green), Trash (red)

### Current Limitations
- Data is **hardcoded** in `lib/data.dart` — no external data source
- `syncWithApi()` in `lib/app.dart` is a **placeholder** (empty function)
- Item model is fixed — no way for consumers to add custom fields
- Card rendering is hardcoded in `lib/status_card.dart` — no customization
- List definitions are hardcoded in `lib/data.dart`
- Sort modes are limited (no custom sort functions)
- No support for multiple data contexts (e.g., switching between companies)
- No on-demand detail loading (all data loaded upfront)

### Key Files
```
lib/
├── main.dart                    # App entry
├── app.dart                     # MyApp StatefulWidget, state management, syncWithApi()
├── item.dart                    # Item data model
├── list_config.dart             # ListConfig model, SortMode enum
├── data.dart                    # Hardcoded sample data + list definitions
├── status_card.dart             # Card widget (collapsed + expanded states)
├── status_card_list.dart        # Reorderable list container
├── status_card_list_example.dart # Example wrapper
├── theme_config.dart            # Theme definitions
└── widgets/
    ├── drawer_menu.dart         # Navigation drawer
    └── list_settings_dialog.dart # Settings modal
```

### Dependencies
- `flutter_html: ^3.0.0-beta.2`
- `uuid: ^4.5.1`
- `cupertino_icons: ^1.0.8`

## What Needs to Change

### 1. Pluggable Data Source

Create an abstract `DataSource` interface that the engine calls for all data operations. Provide two implementations:

```dart
/// Abstract data source — the engine calls these methods
abstract class CardListDataSource {
  /// Load items for a specific list, with sort and pagination
  Future<ItemsPage> loadItems(String listId, {
    SortMode? sortMode,
    int limit = 50,
    int offset = 0,
  });

  /// Load full detail for a single item (called on card expand)
  /// Returns the item with html content populated
  Future<Item> loadItemDetail(String itemId);

  /// Move an item to a different list
  Future<void> moveItem(String itemId, String targetListId);

  /// Update an item's position within its current list (drag-to-reorder)
  Future<void> updateItemPosition(String itemId, int newPosition);

  /// Get all available list definitions
  Future<List<ListConfig>> loadLists();

  /// Update a list's properties (sort mode, name, etc.)
  Future<void> updateList(String listId, ListConfig config);

  /// Get status info (counts per list, last sync time, etc.)
  /// Returns a generic map — consumers define what's in it
  Future<Map<String, dynamic>> getStatus();

  /// Stream of data change notifications (new items, updates)
  /// Engine listens to this to refresh lists
  Stream<DataChangeEvent> get changes;
}

/// Pagination wrapper
class ItemsPage {
  final List<Item> items;
  final int total;
  final int limit;
  final int offset;
}

/// Change notification
class DataChangeEvent {
  final String type;  // 'new_items', 'item_updated', 'list_changed'
  final String? listId;
  final int? count;
}
```

**InMemoryDataSource** — refactor current hardcoded data into this. Keeps the app working as a standalone demo.

**HttpDataSource** — new implementation that calls a REST API. Constructor takes `baseUrl` and optional auth headers. The contractmatch app will use this.

### 2. Configurable Card Rendering

Replace the hardcoded card content in `status_card.dart` with builder callbacks:

```dart
/// Configuration for how cards are rendered
class CardListConfig {
  /// Build the collapsed card content (title area)
  /// Receives the Item + whether it's expanded
  final Widget Function(BuildContext context, Item item) collapsedBuilder;

  /// Build the expanded card detail content
  /// Receives the Item (with full detail loaded) + a loading flag
  final Widget Function(BuildContext context, Item item, bool isLoading) expandedBuilder;

  /// Optional: build trailing widget for collapsed card (e.g., score badge)
  final Widget Function(BuildContext context, Item item)? trailingBuilder;

  /// Optional: build subtitle widget
  final Widget Function(BuildContext context, Item item)? subtitleBuilder;
}
```

**Default builders** — provide sensible defaults that match current behavior (title, subtitle, HTML body). Consumers override with custom builders.

The engine (`StatusCard`, `StatusCardList`) uses these builders instead of directly rendering Item fields. The swipe/drag/expand/collapse mechanics remain in the engine — only the CONTENT of the card is customizable.

### 3. Externalized List Config

Move list definitions out of `data.dart`. Lists are now provided by the `DataSource`:

- `loadLists()` returns the available lists
- Default lists (Review/Saved/Trash) are no longer hardcoded — they come from the data source
- The `InMemoryDataSource` provides the familiar defaults
- The `HttpDataSource` fetches them from the API

### 4. Extended Sort Modes

Add new sort modes that consumers need:

```dart
enum SortMode {
  dateAscending,      // existing
  dateDescending,     // existing
  title,              // existing
  manual,             // existing
  similarityDescending, // NEW — sort by a numeric score field
  deadlineSoonest,      // NEW — sort by due date ascending (nulls last)
  newest,               // NEW — sort by creation/sync date descending
}
```

The `DataSource.loadItems()` receives the `SortMode` — for `HttpDataSource`, this is passed as a query parameter. For `InMemoryDataSource`, sorting is done locally.

### 5. On-Demand Detail Loading

Currently all item data (including HTML) is loaded upfront. Change to:

- List view loads items WITHOUT html content (lightweight)
- On card expand, call `DataSource.loadItemDetail(itemId)` to fetch full content
- Show a loading indicator while detail is fetching
- Cache loaded details in memory to avoid re-fetching

In the `Item` model, `html` becomes nullable:
```dart
class Item {
  String id;
  String title;
  String subtitle;
  String? html;         // null until detail is loaded
  DateTime? dueDate;    // nullable (not all items have dates)
  String status;
  List<String> relatedItemIds;
  Map<String, dynamic> extra;  // extensible metadata (see below)
}
```

### 6. Extensible Item Metadata

Add a generic `extra` map to Item for consumer-specific fields without modifying the core model:

```dart
class Item {
  // ... existing fields ...
  Map<String, dynamic> extra;  // Consumer-specific data
}
```

For contractmatch, `extra` would contain:
```dart
{
  'best_similarity': 0.87,
  'best_capability_name': 'Cybersecurity',
  'matched_capabilities': [...],  // parsed JSON
  'set_aside': ['SBA', 'SDVOSBC'],
  'naics_codes': ['541512'],
  'notice_url': 'https://sam.gov/...',
}
```

The card builders access these via `item.extra['best_similarity']`.

### 7. Data Context Switching (Multi-Company)

Support switching between different data contexts (e.g., companies):

```dart
/// A named data context
class DataContext {
  final String id;      // e.g. 'pneuma-llc'
  final String name;    // e.g. 'Pneuma LLC'
}

/// Extended data source that supports multiple contexts
abstract class MultiContextDataSource extends CardListDataSource {
  /// Get available contexts
  Future<List<DataContext>> loadContexts();

  /// Switch to a different context (reloads lists and items)
  Future<void> switchContext(String contextId);

  /// Current context
  DataContext get currentContext;
}
```

When the user switches context, the engine:
1. Calls `switchContext(newId)`
2. Reloads lists via `loadLists()`
3. Reloads items for the current list
4. Updates the UI

The drawer menu shows a context selector (if `MultiContextDataSource` is provided).

For `InMemoryDataSource`, there's only one context (the default). For `HttpDataSource`, contexts map to companies.

## Implementation Order

### Step 1: Abstract DataSource + InMemoryDataSource
- Create `CardListDataSource` abstract class
- Refactor current hardcoded data into `InMemoryDataSource`
- Update `app.dart` to use DataSource instead of direct data access
- **Test**: App works exactly as before with in-memory data

### Step 2: Card Builder Callbacks
- Create `CardListConfig` with builder functions
- Add default builders that match current rendering
- Update `StatusCard` to use builders
- **Test**: App looks identical with default builders

### Step 3: On-Demand Detail Loading
- Make `Item.html` nullable
- Add loading state to card expand
- Call `loadItemDetail()` on expand, cache result
- **Test**: Expand still works, detail loads (from memory instantly for InMemoryDataSource)

### Step 4: Extended Sort Modes + Externalized Lists
- Add new SortMode values
- Move list definitions to DataSource
- Pass sort mode to `loadItems()`
- **Test**: Sort modes work, lists come from data source

### Step 5: Extensible Item + Extra Fields
- Add `extra` map to Item
- Update default builders to ignore extra (backward compatible)
- **Test**: Existing behavior unchanged, extra fields accessible

### Step 6: HttpDataSource Implementation
- Create `HttpDataSource` that calls REST API endpoints
- Constructor: `HttpDataSource({required String baseUrl, Map<String, String>? headers})`
- Maps API responses to Item/ListConfig models
- Implements all DataSource methods via HTTP calls
- **Test**: Works against a running Cloudflare Worker (or mock server)

### Step 7: Multi-Context Support
- Create `MultiContextDataSource` extension
- Add context selector to drawer menu
- `HttpDataSource` implements multi-context via `?company_id=` param
- **Test**: Switching contexts reloads data

## API Contract (for HttpDataSource)

The HttpDataSource will call these endpoints (matching the contractmatch Worker API):

```
GET  {baseUrl}/notices?list_id={id}&sort={mode}&limit={n}&offset={n}
     → ItemsPage (items without html)

GET  {baseUrl}/notices/{id}
     → Item with full html_content

PUT  {baseUrl}/notices/{id}/list
     Body: { list_id: string }

PUT  {baseUrl}/notices/{id}/position
     Body: { position: number }

GET  {baseUrl}/lists
     → List<ListConfig>

PUT  {baseUrl}/lists/{id}
     Body: { sort_mode: string, ... }

GET  {baseUrl}/companies
     → List<DataContext>

GET  {baseUrl}/status
     → Map<String, dynamic>
```

**Field mapping** (API → Item):
| API field | Item field |
|-----------|-----------|
| `notice_id` | `id` |
| `title` | `title` |
| `"87% — Cybersecurity"` (derived from best_similarity + best_capability_name) | `subtitle` |
| `html_content` | `html` (only from detail endpoint) |
| `response_deadline` | `dueDate` |
| `status` (computed: active/expired) | `status` |
| `best_similarity`, `best_capability_name`, `matched_capabilities`, etc. | `extra` map |

**Field mapping** (API → ListConfig):
| API field | ListConfig field |
|-----------|-----------------|
| `id` | `uuid` |
| `name` | `name` |
| `icon` (string) | `icon` (map to IconData) |
| `color` (hex string) | `color` (parse to Color) |
| `sort_mode` | `sortMode` (map to SortMode enum) |
| `is_default_inbox` | used to set swipe actions (inbox swipes to saved/trash) |

## What NOT to Change

- **Swipe mechanics** — keep the swipe-to-move gesture system as-is
- **Drag-to-reorder** — keep the ReorderableListView mechanics
- **Expand/collapse animation** — keep the expand toggle
- **Theme system** — keep light/dark theming
- **Related items navigation** — keep the cross-item linking and scroll-to
- **flutter_html rendering** — keep for HTML content display
- **StatefulWidget + setState** — no state management migration needed

## Verification

After each step, the app must still work as a standalone demo with `InMemoryDataSource` and default card builders. The refactoring should be invisible to a user — same UI, same behavior.

Final integration test:
1. Run status_card_list with `InMemoryDataSource` — behaves like before
2. Run status_card_list with `HttpDataSource` pointing at `localhost:8787` (Worker dev server) — loads real data from API
3. Expand a card — detail loads on demand
4. Swipe to move — API is called, item moves
5. Switch sort mode — list re-sorts
6. Switch company context — lists and items reload
