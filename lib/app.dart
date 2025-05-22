import 'package:flutter/material.dart';
import 'data.dart';
import 'theme_config.dart';
import 'status_card_list_example.dart';
import 'widgets/drawer_menu.dart';
import 'widgets/list_settings_dialog.dart';
import 'item.dart';
import 'status_card_list.dart';
import 'list_config.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  late List<ListConfig> _listConfigs;
  String _currentList = 'Review';
  late Map<String, List<Item>> _itemLists;

  @override
  void initState() {
    super.initState();
    _listConfigs = parseListConfigs(listConfigJson);
    _itemLists = initializeItemLists(_listConfigs);
    _sortItems(); // Initial sort
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
          _listConfigs.firstWhere((c) => c.name == _currentList);
      currentConfig.sortMode = newMode;
      _sortItems();
    });
  }

  void _sortItems() {
    final currentConfig =
        _listConfigs.firstWhere((c) => c.name == _currentList);
    if (currentConfig.sortMode == SortMode.manual) return;

    final items = _itemLists[_currentList]!;
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

  void _updateStatus(BuildContext scaffoldContext, Item item, String targetList) {
    setState(() {
      final currentListItems = _itemLists[_currentList]!;
      currentListItems.remove(item);
      if (_itemLists.containsKey(targetList)) {
        _itemLists[targetList]!.add(item);
      }
      item.status = targetList.toLowerCase();
      _sortItems(); // Re-sort after updating the list
    });
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(content: Text('${item.title} moved to $targetList')),
    );
  }

  void _switchList(String listName) {
    setState(() {
      _currentList = listName;
      _sortItems(); // Sort the new list
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final Item item = _itemLists[_currentList]!.removeAt(oldIndex);
      _itemLists[_currentList]!.insert(newIndex, item);

      // Switch to manual sorting after reordering
      final currentConfig =
          _listConfigs.firstWhere((c) => c.name == _currentList);
      currentConfig.sortMode = SortMode.manual;
    });
  }

  void _showSettingsDialog(BuildContext context, ListConfig config) {
    showDialog(
      context: context,
      builder: (context) => ListSettingsDialog(
        listConfig: config,
        allConfigs: _listConfigs,
        onSave: (updatedConfig) {
          setState(() {
            // Update the config in _listConfigs
            final index = _listConfigs.indexWhere((c) => c.name == updatedConfig.name);
            _listConfigs[index] = updatedConfig;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig =
        _listConfigs.firstWhere((c) => c.name == _currentList);

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
                  Icon(currentConfig.icon),
                  const SizedBox(width: 8),
                  Text('$_currentList List'),
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
              currentList: _currentList,
              itemLists: _itemLists,
              onListSelected: _switchList,
            ),
            body: StatusCardListExample(
              items: _itemLists[_currentList]!,
              listConfig: currentConfig,
              onStatusChanged: (item, targetList) =>
                  _updateStatus(scaffoldContext, item, targetList),
              onReorder: _reorderItems,
            ),
          );
        },
      ),
    );
  }
}