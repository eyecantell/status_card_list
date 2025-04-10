import 'package:flutter/material.dart';
import 'status_card_list.dart';
import 'list_config.dart';
import 'item.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  late List<ListConfig> _listConfigs;
  String _currentList = 'Review'; // Default to first list
  late Map<String, List<Item>> _itemLists; // Dynamic lists based on config

  @override
  void initState() {
    super.initState();
    _listConfigs = parseListConfigs(listConfigJson);
    _itemLists = {
      for (var config in _listConfigs) config.name: <Item>[],
    };
    // Populate Review list initially
    _itemLists['Review'] = [
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
        status: 'pending',
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
        status: 'pending',
      ),
    ];
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _updateStatus(Item item, String newStatus) {
    setState(() {
      item.status = newStatus;
      // Find the destination list based on the new status
      final currentConfig = _listConfigs.firstWhere((c) => c.name == _currentList);
      final currentListItems = _itemLists[_currentList]!;
      currentListItems.remove(item);

      // Find the list that matches the new status in its swipeActions or buttons
      for (var config in _listConfigs) {
        if (config.swipeActions.containsValue(newStatus) ||
            config.buttons.containsValue(newStatus)) {
          _itemLists[config.name]!.add(item);
          break;
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} set to $newStatus')),
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
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.grey, size: 24),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
          elevation: 1,
        ),
        cardTheme: CardTheme(
          color: Colors.grey[800],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.grey, size: 24),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      themeMode: _themeMode,
      home: Scaffold(
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
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              ..._listConfigs.map((config) => ListTile(
                    title: Text(config.name),
                    onTap: () {
                      _switchList(config.name);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
        body: StatusCardListExample(
          items: _itemLists[_currentList]!,
          listConfig: _listConfigs.firstWhere((c) => c.name == _currentList),
          onStatusChanged: _updateStatus,
        ),
      ),
    );
  }
}

class StatusCardListExample extends StatefulWidget {
  final List<Item> items;
  final ListConfig listConfig;
  final Function(Item, String) onStatusChanged;

  const StatusCardListExample({
    super.key,
    required this.items,
    required this.listConfig,
    required this.onStatusChanged,
  });

  @override
  State<StatusCardListExample> createState() => _StatusCardListExampleState();
}

class _StatusCardListExampleState extends State<StatusCardListExample> {
  @override
  Widget build(BuildContext context) {
    return StatusCardList(
      initialItems: widget.items,
      statusIcons: {
        for (var entry in widget.listConfig.buttons.entries)
          entry.value: iconMap[entry.key]!,
      },
      swipeActions: widget.listConfig.swipeActions,
      onStatusChanged: widget.onStatusChanged,
    );
  }
}