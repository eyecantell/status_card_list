import 'dart:convert';
import 'package:flutter/material.dart';

// Model for list configuration
class ListConfig {
  final String name;
  final Map<String, String> swipeActions; // e.g., {'left': 'saved', 'right': 'dismissed'}
  final Map<String, String> buttons; // e.g., {'check_circle': 'saved', 'delete': 'dismissed'}

  ListConfig({
    required this.name,
    required this.swipeActions,
    required this.buttons,
  });

  factory ListConfig.fromJson(Map<String, dynamic> json) {
    return ListConfig(
      name: json['name'] as String,
      swipeActions: Map<String, String>.from(json['swipeActions']),
      buttons: Map<String, String>.from(json['buttons']),
    );
  }
}

// Sample JSON configuration
final String listConfigJson = '''
[
  {
    "name": "Review",
    "swipeActions": {
      "right": "saved",
      "left": "dismissed"
    },
    "buttons": {
      "check_circle": "saved",
      "delete": "dismissed"
    }
  },
  {
    "name": "Saved",
    "swipeActions": {
      "right": "pending",
      "left": "dismissed"
    },
    "buttons": {
      "refresh": "pending",
      "delete": "dismissed"
    }
  }
]
''';

// Parse JSON into List<ListConfig>
List<ListConfig> parseListConfigs(String jsonString) {
  final List<dynamic> jsonList = jsonDecode(jsonString);
  return jsonList.map((json) => ListConfig.fromJson(json)).toList();
}

// Map icon names to IconData
final Map<String, IconData> iconMap = {
  'check_circle': Icons.check_circle,
  'delete': Icons.delete,
  'refresh': Icons.refresh,
};