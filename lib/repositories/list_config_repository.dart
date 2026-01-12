import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/list_config.dart';
import '../models/sort_mode.dart';
import '../utils/constants.dart';

class ListConfigRepository {
  final SharedPreferences _prefs;
  static const _configsKey = 'list_configs';
  static const _itemListsKey = 'item_lists';

  ListConfigRepository(this._prefs);

  Future<List<ListConfig>> getAllConfigs() async {
    final jsonString = _prefs.getString(_configsKey);
    if (jsonString == null) return _getDefaultConfigs();

    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => ListConfig.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveConfigs(List<ListConfig> configs) async {
    final jsonList = configs.map((c) => c.toJson()).toList();
    await _prefs.setString(_configsKey, jsonEncode(jsonList));
  }

  Future<void> saveConfig(ListConfig config) async {
    final configs = await getAllConfigs();
    final index = configs.indexWhere((c) => c.uuid == config.uuid);
    if (index >= 0) {
      configs[index] = config;
    } else {
      configs.add(config);
    }
    await saveConfigs(configs);
  }

  Future<ListConfig?> getConfig(String uuid) async {
    final configs = await getAllConfigs();
    try {
      return configs.firstWhere((c) => c.uuid == uuid);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, List<String>>> getItemLists() async {
    final jsonString = _prefs.getString(_itemListsKey);
    if (jsonString == null) return _getDefaultItemLists();

    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return jsonMap.map((key, value) =>
        MapEntry(key, (value as List<dynamic>).cast<String>()));
  }

  Future<void> saveItemLists(Map<String, List<String>> itemLists) async {
    await _prefs.setString(_itemListsKey, jsonEncode(itemLists));
  }

  /// Clears all persisted data (useful for testing)
  Future<void> clear() async {
    await _prefs.remove(_configsKey);
    await _prefs.remove(_itemListsKey);
  }

  List<ListConfig> _getDefaultConfigs() {
    return [
      ListConfig(
        uuid: DefaultListIds.review,
        name: 'Review',
        swipeActions: {
          'right': DefaultListIds.saved,
          'left': DefaultListIds.trash,
        },
        buttons: {
          'check_circle': DefaultListIds.saved,
          'delete': DefaultListIds.trash,
        },
        dueDateLabel: 'Due Date',
        sortMode: SortMode.dateAscending,
        iconName: 'rate_review',
        colorValue: 0xFF2196F3,
        cardIcons: [
          CardIconEntry(
            iconName: 'check_circle',
            targetListId: DefaultListIds.saved,
          ),
          CardIconEntry(
            iconName: 'delete',
            targetListId: DefaultListIds.trash,
          ),
        ],
      ),
      ListConfig(
        uuid: DefaultListIds.saved,
        name: 'Saved',
        swipeActions: {
          'right': DefaultListIds.review,
          'left': DefaultListIds.trash,
        },
        buttons: {
          'refresh': DefaultListIds.review,
          'delete': DefaultListIds.trash,
        },
        dueDateLabel: 'Due Date',
        sortMode: SortMode.dateAscending,
        iconName: 'bookmark',
        colorValue: 0xFF4CAF50,
        cardIcons: [
          CardIconEntry(
            iconName: 'refresh',
            targetListId: DefaultListIds.review,
          ),
          CardIconEntry(
            iconName: 'delete',
            targetListId: DefaultListIds.trash,
          ),
        ],
      ),
      ListConfig(
        uuid: DefaultListIds.trash,
        name: 'Trash',
        swipeActions: {
          'right': DefaultListIds.review,
          'left': DefaultListIds.saved,
        },
        buttons: {
          'refresh': DefaultListIds.review,
          'delete_forever': DefaultListIds.trash,
        },
        dueDateLabel: 'Due Date',
        sortMode: SortMode.dateAscending,
        iconName: 'delete',
        colorValue: 0xFFF44336,
        cardIcons: [
          CardIconEntry(
            iconName: 'refresh',
            targetListId: DefaultListIds.review,
          ),
          CardIconEntry(
            iconName: 'check_circle',
            targetListId: DefaultListIds.saved,
          ),
        ],
      ),
    ];
  }

  Map<String, List<String>> _getDefaultItemLists() {
    return {
      DefaultListIds.review: ['1', '2', '3'],
      DefaultListIds.saved: ['4'],
      DefaultListIds.trash: ['5'],
    };
  }
}
