// lib/main.dart
import 'package:flutter/material.dart';
import 'status_card_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Status Card List')),
        body: const StatusCardListExample(),
      ),
    );
  }
}

class StatusCardListExample extends StatefulWidget {
  const StatusCardListExample({super.key});

  @override
  State<StatusCardListExample> createState() => _StatusCardListExampleState();
}

class _StatusCardListExampleState extends State<StatusCardListExample> {
  final List<Item> _items = [
    Item(id: '1', title: 'Task 1', subtitle: 'Due today', text: 'Finish report', status: 'pending'),
    Item(id: '2', title: 'Task 2', subtitle: 'Due tomorrow', text: 'Review code', status: 'pending'),
  ];

  void _updateStatus(Item item, String newStatus) {
    setState(() {
      item.status = newStatus;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} set to $newStatus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatusCardList(
      items: _items,
      statusIcons: {
        'done': Icons.check_circle,
        'rejected': Icons.delete,
      },
      swipeActions: {
        'save': 'done',
        'trash': 'rejected',
      },
      onStatusChanged: _updateStatus,
    );
  }
}