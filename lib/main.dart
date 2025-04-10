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
      initialItems: _items,
      statusIcons: {
        'saved': Icons.check_circle,
        'dismissed': Icons.delete,
      },
      swipeActions: {
        'save': 'saved',
        'trash': 'dismissed',
      },
      onStatusChanged: _updateStatus,
    );
  }
}