import 'package:flutter/material.dart';
import 'item.dart';
import 'status_card_list.dart';
import 'list_config.dart';

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