import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../models/list_config.dart';
import '../models/sort_mode.dart';
import 'card_list_data_source.dart';
import 'items_page.dart';

/// Default list UUIDs for sample data (moved from constants.dart)
class _DefaultIds {
  static const review = '550e8400-e29b-41d4-a716-446655440000';
  static const saved = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
  static const trash = 'c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e';
}

class InMemoryDataSource implements CardListDataSource {
  final SharedPreferences _prefs;
  static const _itemsKey = 'items';
  static const _configsKey = 'list_configs';
  static const _itemListsKey = 'item_lists';

  /// In-memory state
  List<Item> _items = [];
  List<ListConfig> _configs = [];
  Map<String, List<String>> _itemLists = {};

  InMemoryDataSource(this._prefs);

  @override
  String get defaultListId => _DefaultIds.review;

  @override
  Future<void> initialize() async {
    _items = await _loadItemsFromPrefs();
    _configs = await _loadConfigsFromPrefs();
    _itemLists = await _loadItemListsFromPrefs();
  }

  @override
  Future<ItemsPage> loadItems({
    required String listId,
    SortMode sortMode = SortMode.dateAscending,
    int limit = 50,
    int offset = 0,
  }) async {
    final itemIds = _itemLists[listId] ?? [];
    final itemMap = {for (var item in _items) item.id: item};
    var items = itemIds
        .map((id) => itemMap[id])
        .whereType<Item>()
        .toList();

    items = _sortItems(items, sortMode);

    return ItemsPage(
      items: items,
      totalCount: items.length,
      hasMore: false,
      offset: 0,
    );
  }

  @override
  Future<Item> loadItemDetail(String itemId) async {
    return _items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw StateError('Item not found: $itemId'),
    );
  }

  @override
  Future<bool> moveItem({
    required String itemId,
    required String fromListId,
    required String targetListId,
  }) async {
    final fromList = _itemLists[fromListId];
    if (fromList != null) {
      fromList.remove(itemId);
    }

    _itemLists[targetListId] ??= [];
    if (!_itemLists[targetListId]!.contains(itemId)) {
      _itemLists[targetListId]!.add(itemId);
    }

    await _saveItemListsToPrefs();
    return true;
  }

  @override
  Future<void> updateItemPosition({
    required String listId,
    required String itemId,
    required int newPosition,
  }) async {
    final list = _itemLists[listId];
    if (list == null) return;

    final oldIndex = list.indexOf(itemId);
    if (oldIndex < 0) return;

    list.removeAt(oldIndex);
    list.insert(newPosition.clamp(0, list.length), itemId);

    await _saveItemListsToPrefs();
  }

  @override
  Future<List<ListConfig>> loadLists() async {
    return List.unmodifiable(_configs);
  }

  @override
  Future<void> updateList(String listId, ListConfig config) async {
    final index = _configs.indexWhere((c) => c.uuid == listId);
    if (index >= 0) {
      _configs[index] = config;
      await _saveConfigsToPrefs();
    }
  }

  @override
  Future<String?> findListContainingItem(String itemId) async {
    for (final entry in _itemLists.entries) {
      if (entry.value.contains(itemId)) {
        return entry.key;
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> getStatus() async {
    final counts = <String, int>{};
    for (final entry in _itemLists.entries) {
      counts[entry.key] = entry.value.length;
    }
    return {'counts': counts};
  }

  @override
  Future<void> dispose() async {
    // No resources to dispose for in-memory
  }

  // --- Sorting ---

  List<Item> _sortItems(List<Item> items, SortMode mode) {
    if (mode == SortMode.manual) return items;

    final sorted = [...items];
    switch (mode) {
      case SortMode.dateAscending:
      case SortMode.deadlineSoonest:
        sorted.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
      case SortMode.dateDescending:
      case SortMode.newest:
        sorted.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return b.dueDate!.compareTo(a.dueDate!);
        });
      case SortMode.similarityDescending:
        sorted.sort((a, b) {
          final aScore = (a.extra['best_similarity'] as num?) ?? 0;
          final bScore = (b.extra['best_similarity'] as num?) ?? 0;
          return bScore.compareTo(aScore);
        });
      case SortMode.title:
        sorted.sort((a, b) => a.title.compareTo(b.title));
      case SortMode.manual:
        break;
    }
    return sorted;
  }

  // --- SharedPreferences I/O ---

  Future<List<Item>> _loadItemsFromPrefs() async {
    final jsonString = _prefs.getString(_itemsKey);
    if (jsonString == null) return _getDefaultItems();

    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => Item.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ListConfig>> _loadConfigsFromPrefs() async {
    final jsonString = _prefs.getString(_configsKey);
    if (jsonString == null) return _getDefaultConfigs();

    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => ListConfig.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, List<String>>> _loadItemListsFromPrefs() async {
    final jsonString = _prefs.getString(_itemListsKey);
    if (jsonString == null) return _getDefaultItemLists();

    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return jsonMap.map((key, value) =>
        MapEntry(key, (value as List<dynamic>).cast<String>()));
  }

  Future<void> _saveConfigsToPrefs() async {
    final jsonList = _configs.map((c) => c.toJson()).toList();
    await _prefs.setString(_configsKey, jsonEncode(jsonList));
  }

  Future<void> _saveItemListsToPrefs() async {
    await _prefs.setString(_itemListsKey, jsonEncode(_itemLists));
  }

  // --- Default Data ---

  List<Item> _getDefaultItems() {
    final now = DateTime.now();
    return [
      Item(
        id: '1',
        title: 'Task 1',
        subtitle: 'Due today',
        html: '''
          <h2>Finish Report</h2>
          <p>Complete the following sections:</p>
          <ul>
            <li>Introduction</li>
            <li>Analysis</li>
            <li>Conclusion</li>
          </ul>
        ''',
        dueDate: now.subtract(const Duration(days: 1)),
        status: 'Open',
        relatedItemIds: ['2', '4'],
      ),
      Item(
        id: '2',
        title: 'Task 2',
        subtitle: 'Due tomorrow',
        html: '''
          <h2>Review Code</h2>
          <p>Check the following files:</p>
          <table border="1">
            <tr>
              <th>File</th>
              <th>Status</th>
            </tr>
            <tr>
              <td>main.dart</td>
              <td>Pending</td>
            </tr>
            <tr>
              <td>status_card_list.dart</td>
              <td>In Progress</td>
            </tr>
          </table>
        ''',
        dueDate: now,
        status: 'Open',
        relatedItemIds: ['1'],
      ),
      Item(
        id: '3',
        title: 'Prepare Presentation',
        subtitle: 'Due in 3 days',
        html: '''
          <h2>Prepare Slides</h2>
          <p>Include the following topics:</p>
          <ul>
            <li>Project Overview</li>
            <li>Key Findings</li>
            <li>Next Steps</li>
          </ul>
        ''',
        dueDate: now.add(const Duration(days: 2)),
        status: 'Open',
        relatedItemIds: ['4'],
      ),
      Item(
        id: '4',
        title: 'Client Meeting Notes',
        subtitle: 'Due next week',
        html: '''
          <h2>Meeting Summary</h2>
          <p>Action items:</p>
          <ul>
            <li>Follow up on contract</li>
            <li>Schedule next meeting</li>
          </ul>
        ''',
        dueDate: now.add(const Duration(days: 6)),
        status: 'Awarded',
        relatedItemIds: ['1', '3'],
      ),
      Item(
        id: '5',
        title: 'Old Draft',
        subtitle: 'Expired last week',
        html: '''
          <h2>Draft Report</h2>
          <p>Outdated content:</p>
          <ul>
            <li>Initial findings</li>
            <li>Old data</li>
          </ul>
        ''',
        dueDate: now.subtract(const Duration(days: 8)),
        status: 'Expired',
        relatedItemIds: [],
      ),
    ];
  }

  List<ListConfig> _getDefaultConfigs() {
    return [
      ListConfig(
        uuid: _DefaultIds.review,
        name: 'Review',
        swipeActions: {
          'right': _DefaultIds.saved,
          'left': _DefaultIds.trash,
        },
        buttons: {
          'check_circle': _DefaultIds.saved,
          'delete': _DefaultIds.trash,
        },
        dueDateLabel: 'Due Date',
        sortMode: SortMode.dateAscending,
        iconName: 'rate_review',
        colorValue: 0xFF2196F3,
        cardIcons: [
          CardIconEntry(
            iconName: 'check_circle',
            targetListId: _DefaultIds.saved,
          ),
          CardIconEntry(
            iconName: 'delete',
            targetListId: _DefaultIds.trash,
          ),
        ],
      ),
      ListConfig(
        uuid: _DefaultIds.saved,
        name: 'Saved',
        swipeActions: {
          'right': _DefaultIds.review,
          'left': _DefaultIds.trash,
        },
        buttons: {
          'refresh': _DefaultIds.review,
          'delete': _DefaultIds.trash,
        },
        dueDateLabel: 'Due Date',
        sortMode: SortMode.dateAscending,
        iconName: 'bookmark',
        colorValue: 0xFF4CAF50,
        cardIcons: [
          CardIconEntry(
            iconName: 'refresh',
            targetListId: _DefaultIds.review,
          ),
          CardIconEntry(
            iconName: 'delete',
            targetListId: _DefaultIds.trash,
          ),
        ],
      ),
      ListConfig(
        uuid: _DefaultIds.trash,
        name: 'Trash',
        swipeActions: {
          'right': _DefaultIds.review,
          'left': _DefaultIds.saved,
        },
        buttons: {
          'refresh': _DefaultIds.review,
          'delete_forever': _DefaultIds.trash,
        },
        dueDateLabel: 'Due Date',
        sortMode: SortMode.dateAscending,
        iconName: 'delete',
        colorValue: 0xFFF44336,
        cardIcons: [
          CardIconEntry(
            iconName: 'refresh',
            targetListId: _DefaultIds.review,
          ),
          CardIconEntry(
            iconName: 'check_circle',
            targetListId: _DefaultIds.saved,
          ),
        ],
      ),
    ];
  }

  Map<String, List<String>> _getDefaultItemLists() {
    return {
      _DefaultIds.review: ['1', '2', '3'],
      _DefaultIds.saved: ['4'],
      _DefaultIds.trash: ['5'],
    };
  }
}
