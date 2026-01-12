import 'package:flutter/material.dart';
import 'models/item.dart';
import 'models/list_config.dart';
import 'status_card_list.dart';

class StatusCardListExample extends StatelessWidget {
  final List<Item> items;
  final ListConfig listConfig;
  final Function(Item, String) onStatusChanged;
  final Function(int, int) onReorder;
  final List<ListConfig> allConfigs;
  final Map<String, Item> itemMap;
  final Map<String, List<String>> itemLists;
  final Function(String, String) onNavigateToItem;
  final String? expandedItemId;
  final String? navigatedItemId;
  final ScrollController? scrollController; // Added

  const StatusCardListExample({
    super.key,
    required this.items,
    required this.listConfig,
    required this.onStatusChanged,
    required this.onReorder,
    required this.allConfigs,
    required this.itemMap,
    required this.itemLists,
    required this.onNavigateToItem,
    required this.expandedItemId,
    required this.navigatedItemId,
    this.scrollController, // Added
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
      itemMap: itemMap,
      itemLists: itemLists,
      onNavigateToItem: onNavigateToItem,
      expandedItemId: expandedItemId,
      navigatedItemId: navigatedItemId,
      scrollController: scrollController, // Added
    );
  }
}