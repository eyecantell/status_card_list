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
  late Data _data;
  String _currentListUuid = '550e8400-e29b-41d4-a716-446655440000'; // Review

  @override
  void initState() {
    super.initState();
    _data = Data.initialize();
    _sanitizeConfigs();
    _sortItems();
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _setSortMode(SortMode newMode) {
    setState(() {
      final currentConfig = _data.listConfigs.firstWhere((c) => c.uuid == _currentListUuid);
      currentConfig.sortMode = newMode;
      _sortItems();
    });
  }

  void _sortItems() {
    final currentConfig = _data.listConfigs.firstWhere((c) => c.uuid == _currentListUuid);
    if (currentConfig.sortMode == SortMode.manual) return;

    final itemUuids = _data.itemLists[_currentListUuid]!;
    switch (currentConfig.sortMode) {
      case SortMode.dateAscending:
        itemUuids.sort((a, b) => _data.itemMap[a]!.dueDate.compareTo(_data.itemMap[b]!.dueDate));
        break;
      case SortMode.dateDescending:
        itemUuids.sort((a, b) => _data.itemMap[b]!.dueDate.compareTo(_data.itemMap[a]!.dueDate));
        break;
      case SortMode.title:
        itemUuids.sort((a, b) => _data.itemMap[a]!.title.compareTo(_data.itemMap[b]!.title));
        break;
      case SortMode.manual:
        break;
    }
  }

  void _updateStatus(BuildContext scaffoldContext, Item item, String targetListUuid) {
    setState(() {
      final currentConfig = _data.listConfigs.firstWhere((c) => c.uuid == _currentListUuid);
      _data.itemLists[_currentListUuid]!.remove(item.id);
      if (_data.itemLists.containsKey(targetListUuid)) {
        _data.itemLists[targetListUuid]!.add(item.id);
      }
      final targetConfig = _data.listConfigs.firstWhere((c) => c.uuid == targetListUuid);
      // Removed: item.status = targetConfig.name.toLowerCase();
      _sortItems();
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(content: Text('${item.title} moved to ${targetConfig.name}')),
      );
    });
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
      final itemUuid = _data.itemLists[_currentListUuid]!.removeAt(oldIndex);
      _data.itemLists[_currentListUuid]!.insert(newIndex, itemUuid);
      final currentConfig = _data.listConfigs.firstWhere((c) => c.uuid == _currentListUuid);
      currentConfig.sortMode = SortMode.manual;
    });
  }

  void _sanitizeConfigs() {
    final listUuids = _data.listConfigs.map((config) => config.uuid).toSet();
    for (var config in _data.listConfigs) {
      config.swipeActions.removeWhere((key, targetUuid) => !listUuids.contains(targetUuid));
      config.buttons.removeWhere((key, targetUuid) => !listUuids.contains(targetUuid));
      config.cardIcons.removeWhere((entry) => !listUuids.contains(entry.value));
    }
    _data.itemLists.removeWhere((listUuid, _) => !listUuids.contains(listUuid));
    for (var itemList in _data.itemLists.values) {
      itemList.removeWhere((itemUuid) => !_data.itemMap.containsKey(itemUuid));
    }
  }

  void _showSettingsDialog(BuildContext context, ListConfig config) {
    showDialog(
      context: context,
      builder: (context) => ListSettingsDialog(
        listConfig: config,
        allConfigs: _data.listConfigs,
        onSave: (updatedConfig) {
          setState(() {
            final index = _data.listConfigs.indexWhere((c) => c.uuid == updatedConfig.uuid);
            _data.listConfigs[index] = updatedConfig;
            _sanitizeConfigs();
          });
        },
      ),
    );
  }

  Future<void> syncWithApi() async {
    final dataJson = {
      'items': _data.items.map((item) => {
            'id': item.id,
            'title': item.title,
            'subtitle': item.subtitle,
            'html': item.html,
            'dueDate': item.dueDate.toIso8601String(),
            'status': item.status,
          }).toList(),
      'listConfigs': _data.listConfigs.map((config) => config.toJson()).toList(),
      'itemLists': _data.itemLists,
    };
    String jsonString = jsonEncode(dataJson);
    String apiResponse = jsonString; // Placeholder for actual API call
    final responseJson = jsonDecode(apiResponse);
    setState(() {
      _data = Data(
        items: (responseJson['items'] as List<dynamic>)
            .map((json) => Item(
                  id: json['id'],
                  title: json['title'],
                  subtitle: json['subtitle'],
                  html: json['html'],
                  dueDate: DateTime.parse(json['dueDate']),
                  status: json['status'],
                ))
            .toList(),
        itemMap: {
          for (var item in (responseJson['items'] as List<dynamic>)
              .map((json) => Item(
                    id: json['id'],
                    title: json['title'],
                    subtitle: json['subtitle'],
                    html: json['html'],
                    dueDate: DateTime.parse(json['dueDate']),
                    status: json['status'],
                  )))
            item.id: item
        },
        listConfigs: (responseJson['listConfigs'] as List<dynamic>)
            .map((json) => ListConfig.fromJson(json))
            .toList(),
        itemLists: Map<String, List<String>>.from(
            responseJson['itemLists'].map((key, value) => MapEntry(key, List<String>.from(value)))),
      );
      _sanitizeConfigs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = _data.listConfigs.firstWhere((c) => c.uuid == _currentListUuid);
    final currentItems = _data.itemLists[_currentListUuid]!.map((uuid) => _data.itemMap[uuid]!).toList();

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
              listConfigs: _data.listConfigs,
              currentListUuid: _currentListUuid,
              itemLists: _data.itemLists,
              onListSelected: _switchList,
            ),
            body: StatusCardListExample(
              items: currentItems,
              listConfig: currentConfig,
              onStatusChanged: (item, targetListUuid) => _updateStatus(scaffoldContext, item, targetListUuid),
              onReorder: _reorderItems,
              allConfigs: _data.listConfigs,
            ),
          );
        },
      ),
    );
  }
}