import 'package:flutter/material.dart';

/// Icon mapping for card action buttons
const Map<String, IconData> iconMap = {
  'check_circle': Icons.check_circle,
  'delete': Icons.delete,
  'refresh': Icons.refresh,
  'delete_forever': Icons.delete_forever,
};

/// Icon mapping for list icons (in drawer, app bar)
const Map<String, IconData> iconMapForLists = {
  'list': Icons.list,
  'rate_review': Icons.rate_review,
  'bookmark': Icons.bookmark,
  'delete': Icons.delete,
  'folder': Icons.folder,
  'star': Icons.star,
  'inbox': Icons.inbox,
  'archive': Icons.archive,
};

/// Available colors for list customization
const List<Color> availableColors = [
  Colors.blue,
  Colors.green,
  Colors.red,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.pink,
  Colors.amber,
];

/// Default list UUIDs for sample data
class DefaultListIds {
  static const review = '550e8400-e29b-41d4-a716-446655440000';
  static const saved = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
  static const trash = 'c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e';
}
