import '../models/item.dart';
import '../models/list_config.dart';
import '../models/sort_mode.dart';
import 'items_page.dart';

abstract class CardListDataSource {
  /// Initialize the data source (called once at startup).
  Future<void> initialize();

  /// Load a page of items for a list. Items may have null html (load via loadItemDetail).
  /// Sorting is handled by the DataSource (server-side for HTTP, local for in-memory).
  Future<ItemsPage> loadItems({
    required String listId,
    SortMode sortMode = SortMode.dateAscending,
    int limit = 50,
    int offset = 0,
  });

  /// Load full detail for a single item (html populated). Used on card expand.
  Future<Item> loadItemDetail(String itemId);

  /// Move an item between lists. Returns true on success.
  Future<bool> moveItem({
    required String itemId,
    required String fromListId,
    required String targetListId,
  });

  /// Update item position within a list (for drag-to-reorder).
  Future<void> updateItemPosition({
    required String listId,
    required String itemId,
    required int newPosition,
  });

  /// Load all list configurations, including item counts per list.
  Future<List<ListConfig>> loadLists();

  /// Update a list's configuration (sort mode, name, icon, color, etc.).
  Future<void> updateList(String listId, ListConfig config);

  /// Find which list contains a given item. Returns list ID or null.
  /// Used for related item navigation.
  Future<String?> findListContainingItem(String itemId);

  /// Get status info (counts per list, last sync, connection health, etc.).
  Future<Map<String, dynamic>> getStatus();

  /// The default list ID to select on startup (e.g. the "inbox" list).
  String get defaultListId;

  /// Dispose resources.
  Future<void> dispose();
}
