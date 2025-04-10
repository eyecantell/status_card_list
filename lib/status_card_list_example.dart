import 'package:flutter/material.dart';
import 'item.dart';
import 'status_card_list.dart';
import 'list_config.dart';

class StatusCardListExample extends StatelessWidget {
  final List<Item> items;
  final ListConfig listConfig;
  final Function(Item, String) onStatusChanged;
  final Function(int, int) onReorder; // New callback

  const StatusCardListExample({
    super.key,
    required this.items,
    required this.listConfig,
    required this.onStatusChanged,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return StatusCardList(
      items: items,
      statusIcons: {
        for (var entry in listConfig.buttons.entries)
          entry.value: iconMap[entry.key]!,
      },
      swipeActions: listConfig.swipeActions,
      onStatusChanged: onStatusChanged,
      onReorder: onReorder, // Pass it through
    );
  }
}