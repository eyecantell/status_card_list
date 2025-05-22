import 'package:flutter/material.dart';
import 'item.dart';
import 'status_card_list.dart';
import 'list_config.dart';

class StatusCardListExample extends StatelessWidget {
  final List<Item> items;
  final ListConfig listConfig;
  final Function(Item, String) onStatusChanged;
  final Function(int, int) onReorder;
  final List<ListConfig> allConfigs;

  const StatusCardListExample({
    super.key,
    required this.items,
    required this.listConfig,
    required this.onStatusChanged,
    required this.onReorder,
    required this.allConfigs,
  });

  @override
  Widget build(BuildContext context) {
    // Map buttons to use target list icons for statusIcons
    final Map<String, IconData> statusIcons = {};
    for (var entry in listConfig.buttons.entries) {
      final targetUuid = entry.value;
      final targetConfig = allConfigs.firstWhere((config) => config.uuid == targetUuid);
      statusIcons[targetConfig.name] = targetConfig.icon; // Use the target list's icon
    }

    return StatusCardList(
      items: items,
      statusIcons: statusIcons,
      swipeActions: listConfig.swipeActions,
      onStatusChanged: onStatusChanged,
      onReorder: onReorder,
      dueDateLabel: listConfig.dueDateLabel,
      listColor: listConfig.color,
      allConfigs: allConfigs,
      cardIcons: listConfig.cardIcons,
    );
  }
}