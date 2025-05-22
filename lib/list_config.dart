import 'dart:convert';
import 'package:flutter/material.dart';

// Enum to represent sorting modes
enum SortMode {
  dateAscending,
  dateDescending,
  title,
  manual,
}

class ListConfig {
  final String name;
  final Map<String, String> swipeActions;
  final Map<String, String> buttons;
  final String dueDateLabel;
  SortMode sortMode;
  IconData icon; // New field for list icon

  ListConfig({
    required this.name,
    required this.swipeActions,
    required this.buttons,
    required this.dueDateLabel,
    required this.sortMode,
    required this.icon,
  });

  factory ListConfig.fromJson(Map<String, dynamic> json) {
    return ListConfig(
      name: json['name'] as String,
      swipeActions: Map<String, String>.from(json['swipeActions']),
      buttons: Map<String, String>.from(json['buttons']),
      dueDateLabel: json['dueDateLabel'] as String? ?? 'Due Date',
      sortMode: SortMode.values.firstWhere(
        (e) => e.toString() == 'SortMode.${json['sortMode']}',
        orElse: () => SortMode.dateAscending,
      ),
      icon: iconMapForLists[json['icon']] ?? Icons.list,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'swipeActions': swipeActions,
      'buttons': buttons,
      'dueDateLabel': dueDateLabel,
      'sortMode': sortMode.toString().split('.').last,
      'icon': iconMapForLists.entries
          .firstWhere((entry) => entry.value == icon, orElse: () => MapEntry('list', Icons.list))
          .key,
    };
  }
}

final String listConfigJson = '''
[
    {
        "name": "Review",
        "swipeActions": {
            "right": "Saved",
            "left": "Trash"
        },
        "buttons": {
            "check_circle": "Saved",
            "delete": "Trash"
        },
        "dueDateLabel": "Due Date",
        "sortMode": "dateAscending",
        "icon": "rate_review"
    },
    {
        "name": "Saved",
        "swipeActions": {
            "right": "Review",
            "left": "Trash"
        },
        "buttons": {
            "refresh": "Review",
            "delete": "Trash"
        },
        "dueDateLabel": "Due Date",
        "sortMode": "dateAscending",
        "icon": "bookmark"
    },
    {
        "name": "Trash",
        "swipeActions": {
            "right": "Review",
            "left": "Trash"
        },
        "buttons": {
            "refresh": "Review",
            "delete_forever": "Trash"
        },
        "dueDateLabel": "Due Date",
        "sortMode": "dateAscending",
        "icon": "delete"
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

// Map for list icons (used in settings dialog)
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