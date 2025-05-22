import 'package:flutter/material.dart';
import 'data.dart';
import 'theme_config.dart';
import 'status_card_list_example.dart';
import 'widgets/drawer_menu.dart';
import 'widgets/list_settings_dialog.dart';
import 'item.dart';
import 'status_card_list.dart';
import 'list_config.dart';
import 'dart:convert';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  late List<ListConfig> _listConfigs;
  String _currentListUuid = '550e8400-e29b-41d4-a716-446655440000'; // UUID for Review
  late Map<String, List<Item>> _itemLists;

  @override
  void initState() {
    super.initState();
    _listConfigs = parseListConfigs(listConfigJson);
    _sanitizeConfigs();
    _itemLists = initializeItemLists(_listConfigs);
    _sortItems();
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _setSortMode(SortMode newMode) {
    setState(() {
      final currentConfig =
          _listConfigs.firstWhere((c) => c.uuid == _currentListUuid);
      currentConfig.sortMode = newMode;
      _sortItems();
    });
  }

  void _sortItems() {
    final currentConfig =
        _listConfigs.firstWhere((c) => c.uuid == _currentListUuid);
    if (currentConfig.sortMode == SortMode.manual) return;

    final items = _itemLists[_currentListUuid]!;
    switch (currentConfig.sortMode) {
      case SortMode.dateAscending:
        items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case SortMode.dateDescending:
        items.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        break;
      case SortMode.title:
        items.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortMode.manual:
        break;
    }
  }

  void _updateStatus(BuildContext scaffoldContext, Item item, String targetListUuid) {
    setState(() {
      final currentListItems = _itemLists[_currentListUuid]!;
      currentListItems.remove(item);
      if (_itemLists.containsKey(targetListUuid)) {
        _itemLists[targetListUuid]!.add(item);
      }
      final targetConfig = _listConfigs.firstWhere((c) => c.uuid == targetListUuid);
      item.status = targetConfig.name.toLowerCase();
      _sortItems();
    });
    final targetConfig = _listConfigs.firstWhere((c) => c.uuid == targetListUuid);
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(content: Text('${item.title} moved to ${targetConfig.name}')),
    );
  }

  void _switchList(String listUuid) {
    setState(() {
      _currentListUuid = listUuid;
      _sortItems();
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final Item item = _itemLists[_currentListUuid]!.removeAt(oldIndex);
      _itemLists[_currentListUuid]!.insert(newIndex, item);

      final currentConfig =
          _listConfigs.firstWhere((c) => c.uuid == _currentListUuid);
      currentConfig.sortMode = SortMode.manual;
    });
  }

  void _sanitizeConfigs() {
    final listUuids = _listConfigs.map((config) => config.uuid).toSet();
    for (var config in _listConfigs) {
      config.swipeActions.removeWhere((key, targetUuid) => !listUuids.contains(targetUuid));
      config.buttons.removeWhere((key, targetUuid) => !listUuids.contains(targetUuid));
      config.cardIcons.removeWhere((entry) => !listUuids.contains(entry.value));
    }
  }

  void _showSettingsDialog(BuildContext context, ListConfig config) {
    showDialog(
      context: context,
      builder: (context) => ListSettingsDialog(
        listConfig: config,
        allConfigs: _listConfigs,
        onSave: (updatedConfig) {
          setState(() {
            final index = _listConfigs.indexWhere((c) => c.uuid == updatedConfig.uuid);
            _listConfigs[index] = updatedConfig;
            _sanitizeConfigs();
          });
        },
      ),
    );
  }

  Future<void> syncWithApi() async {
    List<Map<String, dynamic>> listConfigsJson = _listConfigs.map((config) => config.toJson()).toList();
    String jsonString = jsonEncode(listConfigsJson);
    String apiResponse = jsonString;
    List<dynamic> jsonList = jsonDecode(apiResponse);
    setState(() {
      _listConfigs = jsonList.map((json) => ListConfig.fromJson(json)).toList();
      _sanitizeConfigs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig =
        _listConfigs.firstWhere((c) => c.uuid == _currentListUuid);

    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: Builder(
        builder: (BuildContext scaffoldContext) {
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: currentConfig.color, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(currentConfig.icon, color: currentConfig.color),
                        const SizedBox(width: 8),
                        Text('${currentConfig.name} List'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _showSettingsDialog(scaffoldContext, currentConfig),
                    tooltip: 'List Settings',
                  ),
                ],
              ),
              actions: [
                DropdownButton<SortMode>(
                  value: currentConfig.sortMode,
                  icon: const Icon(Icons.sort),
                  onChanged: (SortMode? newValue) {
                    if (newValue != null) {
                      _setSortMode(newValue);
                    }
                  },
                  items: SortMode.values.map((SortMode mode) {
                    String label;
                    switch (mode) {
                      case SortMode.dateAscending:
                        label = 'Date Ascending';
                        break;
                      case SortMode.dateDescending:
                        label = 'Date Descending';
                        break;
                      case SortMode.title:
                        label = 'Title';
                        break;
                      case SortMode.manual:
                        label = 'Manual';
                        break;
                    }
                    return DropdownMenuItem<SortMode>(
                      value: mode,
                      child: Text(label),
                    );
                  }).toList(),
                ),
                IconButton(
                  icon: Icon(
                    _themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                  ),
                  onPressed: _toggleTheme,
                ),
              ],
            ),
            drawer: DrawerMenu(
              listConfigs: _listConfigs,
              currentListUuid: _currentListUuid,
              itemLists: _itemLists,
              onListSelected: _switchList,
            ),
            body: StatusCardListExample(
              items: _itemLists[_currentListUuid]!,
              listConfig: currentConfig,
              onStatusChanged: (item, targetListUuid) =>
                  _updateStatus(scaffoldContext, item, targetListUuid),
              onReorder: _reorderItems,
              allConfigs: _listConfigs,
            ),
          );
        },
      ),
    );
  }
}