import 'package:flutter/material.dart';
import 'package:status_card_list/list_config.dart';
import 'item.dart';
import 'status_card.dart';

class StatusCardList extends StatelessWidget {
  final List<Item> items;
  final Map<String, IconData> statusIcons;
  final Map<String, String> swipeActions;
  final Function(Item, String) onStatusChanged;
  final Function(int, int) onReorder;
  final String dueDateLabel;
  final Color listColor;
  final List<ListConfig> allConfigs;
  final List<MapEntry<String, String>> cardIcons;
  final Map<String, Item> itemMap; // Added
  final Map<String, List<String>> itemLists; // Added
  final Function(String, String) onNavigateToItem; // Added
  final String? expandedItemId; // Added

  const StatusCardList({
    super.key,
    required this.items,
    required this.statusIcons,
    required this.swipeActions,
    required this.onStatusChanged,
    required this.onReorder,
    required this.dueDateLabel,
    required this.listColor,
    required this.allConfigs,
    required this.cardIcons,
    required this.itemMap, // Added
    required this.itemLists, // Added
    required this.onNavigateToItem, // Added
    required this.expandedItemId, // Added
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(iconTheme: Theme.of(context).iconTheme),
      child: ReorderableListView(
        buildDefaultDragHandles: false,
        onReorder: onReorder,
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
              onReorder: onReorder,
              dueDateLabel: dueDateLabel,
              listColor: listColor,
              allConfigs: allConfigs,
              cardIcons: cardIcons,
              itemMap: itemMap, // Added
              itemLists: itemLists, // Added
              onNavigateToItem: onNavigateToItem, // Added
              isExpanded: expandedItemId == items[index].id, // Added
            ),
        ],
      ),
    );
  }
}