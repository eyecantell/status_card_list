import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

// Enum to represent sorting modes
enum SortMode {
  dateAscending,
  dateDescending,
  title,
  manual,
}

class ListConfig {
  final String uuid;
  final String name;
  final Map<String, String> swipeActions;
  final Map<String, String> buttons;
  final String dueDateLabel;
  SortMode sortMode;
  IconData icon;
  Color color;
  List<MapEntry<String, String>> cardIcons;

  ListConfig({
    String? uuid,
    required this.name,
    required this.swipeActions,
    required this.buttons,
    required this.dueDateLabel,
    required this.sortMode,
    required this.icon,
    required this.color,
    List<MapEntry<String, String>>? cardIcons,
  })  : uuid = uuid ?? const Uuid().v4(),
        cardIcons = cardIcons ?? buttons.entries.toList().take(5).toList();

  factory ListConfig.fromJson(Map<String, dynamic> json) {
    Color parseColor(String? colorStr) {
      try {
        if (colorStr == null) return Colors.blue;
        String hexStr = colorStr;
        if (hexStr.startsWith('#')) {
          hexStr = '0xFF${hexStr.substring(1)}';
        } else if (hexStr.startsWith('0x')) {
          // Already in the correct format
        } else {
          hexStr = '0xFF$hexStr';
        }
        return Color(int.parse(hexStr));
      } catch (e) {
        return Colors.blue;
      }
    }

    List<MapEntry<String, String>> parseCardIcons(dynamic jsonIcons) {
      if (jsonIcons == null) {
        final buttons = Map<String, String>.from(json['buttons']);
        return buttons.entries.toList().take(5).toList();
      }
      final List<dynamic> iconList = jsonIcons as List<dynamic>;
      return iconList
          .map((entry) => MapEntry<String, String>(entry[0] as String, entry[1] as String))
          .toList();
    }

    return ListConfig(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      swipeActions: Map<String, String>.from(json['swipeActions']),
      buttons: Map<String, String>.from(json['buttons']),
      dueDateLabel: json['dueDateLabel'] as String? ?? 'Due Date',
      sortMode: SortMode.values.firstWhere(
        (e) => e.toString() == 'SortMode.${json['sortMode']}',
        orElse: () => SortMode.dateAscending,
      ),
      icon: iconMapForLists[json['icon']] ?? Icons.list,
      color: parseColor(json['color'] as String?),
      cardIcons: parseCardIcons(json['cardIcons']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'swipeActions': swipeActions,
      'buttons': buttons,
      'dueDateLabel': dueDateLabel,
      'sortMode': sortMode.toString().split('.').last,
      'icon': iconMapForLists.entries
          .firstWhere((entry) => entry.value == icon, orElse: () => MapEntry('list', Icons.list))
          .key,
      'color': '0x${color.value.toRadixString(16).padLeft(8, '0')}',
      'cardIcons': cardIcons.map((entry) => [entry.key, entry.value]).toList(),
    };
  }
}

final String listConfigJson = '''
[
    {
        "uuid": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Review",
        "swipeActions": {
            "right": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            "left": "c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e"
        },
        "buttons": {
            "check_circle": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
            "delete": "c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e"
        },
        "dueDateLabel": "Due Date",
        "sortMode": "dateAscending",
        "icon": "rate_review",
        "color": "0xFF2196F3",
        "cardIcons": [
            ["check_circle", "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"],
            ["delete", "c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e"]
        ]
    },
    {
        "uuid": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        "name": "Saved",
        "swipeActions": {
            "right": "550e8400-e29b-41d4-a716-446655440000",
            "left": "c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e"
        },
        "buttons": {
            "refresh": "550e8400-e29b-41d4-a716-446655440000",
            "delete": "c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e"
        },
        "dueDateLabel": "Due Date",
        "sortMode": "dateAscending",
        "icon": "bookmark",
        "color": "0xFF4CAF50",
        "cardIcons": [
            ["refresh", "550e8400-e29b-41d4-a716-446655440000"],
            ["delete", "c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e"]
        ]
    },
    {
        "uuid": "c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e",
        "name": "Trash",
        "swipeActions": {
            "right": "550e8400-e29b-41d4-a716-446655440000",
            "left": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
        },
        "buttons": {
            "refresh": "550e8400-e29b-41d4-a716-446655440000",
            "delete_forever": "c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e"
        },
        "dueDateLabel": "Due Date",
        "sortMode": "dateAscending",
        "icon": "delete",
        "color": "0xFFF44336",
        "cardIcons": [
            ["refresh", "550e8400-e29b-41d4-a716-446655440000"],
            ["check_circle", "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"]
        ]
    }
]
''';

List<ListConfig> parseListConfigs(String jsonString) {
  final List<dynamic> jsonList = jsonDecode(jsonString);
  return jsonList.map((json) => ListConfig.fromJson(json)).toList();
}

final Map<String, IconData> iconMap = {
  'check_circle': Icons.check_circle,
  'delete': Icons.delete,
  'refresh': Icons.refresh,
  'delete_forever': Icons.delete_forever,
};

final Map<String, IconData> iconMapForLists = {
  'list': Icons.list,
  'rate_review': Icons.rate_review,
  'bookmark': Icons.bookmark,
  'delete': Icons.delete,
  'folder': Icons.folder,
  'star': Icons.star,
  'inbox': Icons.inbox,
  'archive': Icons.archive,
};

final List<Color> availableColors = [
  Colors.blue,
  Colors.green,
  Colors.red,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.pink,
  Colors.amber,
];