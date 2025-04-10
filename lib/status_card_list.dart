import 'package:flutter/material.dart';
import 'item.dart';
import 'status_card.dart';

class StatusCardList extends StatefulWidget {
  final List<Item> initialItems;
  final Map<String, IconData> statusIcons;
  final Map<String, String> swipeActions;
  final Function(Item, String) onStatusChanged;

  const StatusCardList({
    super.key,
    required this.initialItems,
    required this.statusIcons,
    required this.swipeActions,
    required this.onStatusChanged,
  });

  @override
  State<StatusCardList> createState() => _StatusCardListState();
}

class _StatusCardListState extends State<StatusCardList> {
  late List<Item> items;

  @override
  void initState() {
    super.initState();
    items = List.from(widget.initialItems);
  }

  @override
  void didUpdateWidget(StatusCardList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialItems != oldWidget.initialItems) {
      setState(() {
        items = List.from(widget.initialItems);
      });
    }
  }

  void _handleStatusChanged(Item item, String newStatus) {
    widget.onStatusChanged(item, newStatus);
    setState(() {
      items.removeWhere((i) => i.id == item.id);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final Item item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        iconTheme: Theme.of(context).iconTheme,
      ),
      child: ReorderableListView(
        onReorder: _onReorder,
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
              statusIcons: widget.statusIcons,
              swipeActions: widget.swipeActions,
              onStatusChanged: _handleStatusChanged,
            ),
        ],
      ),
    );
  }
}