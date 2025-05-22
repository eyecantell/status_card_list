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
  SortMode sortMode; // New field for sort mode

  ListConfig({
    required this.name,
    required this.swipeActions,
    required this.buttons,
    required this.dueDateLabel,
    required this.sortMode,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'swipeActions': swipeActions,
      'buttons': buttons,
      'dueDateLabel': dueDateLabel,
      'sortMode': sortMode.toString().split('.').last,
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
        "sortMode": "dateAscending"
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
        "sortMode": "dateAscending"
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
        "sortMode": "dateAscending"
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