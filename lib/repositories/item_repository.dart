import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class ItemRepository {
  final SharedPreferences _prefs;
  static const _itemsKey = 'items';

  ItemRepository(this._prefs);

  Future<List<Item>> getAllItems() async {
    final jsonString = _prefs.getString(_itemsKey);
    if (jsonString == null) return _getDefaultItems();

    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => Item.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveItems(List<Item> items) async {
    final jsonList = items.map((item) => item.toJson()).toList();
    await _prefs.setString(_itemsKey, jsonEncode(jsonList));
  }

  Future<void> saveItem(Item item) async {
    final items = await getAllItems();
    final index = items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
    await saveItems(items);
  }

  Future<void> deleteItem(String id) async {
    final items = await getAllItems();
    items.removeWhere((item) => item.id == id);
    await saveItems(items);
  }

  Future<Item?> getItem(String id) async {
    final items = await getAllItems();
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clears all persisted items (useful for testing)
  Future<void> clear() async {
    await _prefs.remove(_itemsKey);
  }

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
}
