import 'package:flutter/material.dart';
import 'data.dart';
import 'theme_config.dart';
import 'status_card_list_example.dart';
import 'widgets/drawer_menu.dart';
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
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _updateStatus(BuildContext scaffoldContext, Item item, String targetList) {
    setState(() {
      final currentListItems = _itemLists[_currentList]!;
      currentListItems.remove(item);
      if (_itemLists.containsKey(targetList)) {
        _itemLists[targetList]!.add(item);
      }
      item.status = targetList.toLowerCase();
    });
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(content: Text('${item.title} moved to $targetList')),
    );
  }

  void _switchList(String listName) {
    setState(() {
      _currentList = listName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: Builder(
        builder: (BuildContext scaffoldContext) {
          return Scaffold(
            appBar: AppBar(
              title: Text('$_currentList List'),
              actions: [
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
              listConfig: _listConfigs.firstWhere((c) => c.name == _currentList),
              onStatusChanged: (item, targetList) => _updateStatus(scaffoldContext, item, targetList),
            ),
          );
        },
      ),
    );
  }
}