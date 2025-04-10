import 'package:flutter/material.dart';
import 'item.dart';
import 'status_card.dart';

class StatusCardList extends StatelessWidget {
  final List<Item> items;
  final Map<String, IconData> statusIcons;
  final Map<String, String> swipeActions;
  final Function(Item, String) onStatusChanged;
  final Function(int, int) onReorder; // New callback

  const StatusCardList({
    super.key,
    required this.items,
    required this.statusIcons,
    required this.swipeActions,
    required this.onStatusChanged,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(iconTheme: Theme.of(context).iconTheme),
      child: ReorderableListView(
        onReorder: onReorder, // Use the callback directly
        proxyDecorator: (child, index, animation) => Material(
          elevation: 4,
          color: Theme.of(context).cardTheme.color,
          child: child,
        ),
        children: [
          for (int index = 0; index < items.length; index++)
            StatusCard(
              key: ValueKey(items[index].id),
              item: items[index],
              index: index,
              statusIcons: statusIcons,
              swipeActions: swipeActions,
              onStatusChanged: onStatusChanged,
            ),
        ],
      ),
    );
  }
}