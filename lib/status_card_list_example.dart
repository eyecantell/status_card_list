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
  final Map<String, Item> itemMap; // Added
  final Map<String, List<String>> itemLists; // Added
  final Function(String, String) onNavigateToItem; // Added
  final String? expandedItemId; // Added

  const StatusCardListExample({
    super.key,
    required this.items,
    required this.listConfig,
    required this.onStatusChanged,
    required this.onReorder,
    required this.allConfigs,
    required this.itemMap, // Added
    required this.itemLists, // Added
    required this.onNavigateToItem, // Added
    required this.expandedItemId, // Added
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, IconData> statusIcons = {};
    for (var entry in listConfig.buttons.entries) {
      final targetUuid = entry.value;
      final targetConfig = allConfigs.firstWhere((config) => config.uuid == targetUuid, orElse: () => listConfig);
      statusIcons[targetConfig.name] = targetConfig.icon;
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
      itemMap: itemMap, // Added
      itemLists: itemLists, // Added
      onNavigateToItem: onNavigateToItem, // Added
      expandedItemId: expandedItemId, // Added
    );
  }
}