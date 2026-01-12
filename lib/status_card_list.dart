import 'package:flutter/material.dart';
import 'package:status_card_list/list_config.dart';
import 'item.dart';
import 'status_card.dart';

class StatusCardList extends StatefulWidget {
  final List<Item> items;
  final Map<String, IconData> statusIcons;
  final Map<String, String> swipeActions;
  final Function(Item, String) onStatusChanged;
  final Function(int, int) onReorder;
  final String dueDateLabel;
  final Color listColor;
  final List<ListConfig> allConfigs;
  final List<MapEntry<String, String>> cardIcons;
  final Map<String, Item> itemMap;
  final Map<String, List<String>> itemLists;
  final Function(String, String) onNavigateToItem;
  final String? expandedItemId;
  final String? navigatedItemId;
  final ScrollController? scrollController;

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
    required this.itemMap,
    required this.itemLists,
    required this.onNavigateToItem,
    required this.expandedItemId,
    required this.navigatedItemId,
    this.scrollController,
  });

  @override
  State<StatusCardList> createState() => _StatusCardListState();
}

class _StatusCardListState extends State<StatusCardList> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(iconTheme: Theme.of(context).iconTheme),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const ClampingScrollPhysics(),
        child: ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false, // Disable default drag handle
          onReorder: (oldIndex, newIndex) {
            print('Reordering from $oldIndex to $newIndex'); // Debug log
            widget.onReorder(oldIndex, newIndex);
          },
          proxyDecorator: (child, index, animation) {
            return Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: MediaQuery.of(context).size.width - 32,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.items[index].title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            );
          },
          children: [
            for (int index = 0; index < widget.items.length; index++)
              ReorderableDelayedDragStartListener(
                key: ValueKey(widget.items[index].id),
                index: index,
                child: StatusCard(
                  item: widget.items[index],
                  index: index,
                  statusIcons: widget.statusIcons,
                  swipeActions: widget.swipeActions,
                  onStatusChanged: widget.onStatusChanged,
                  onReorder: widget.onReorder,
                  dueDateLabel: widget.dueDateLabel,
                  listColor: widget.listColor,
                  allConfigs: widget.allConfigs,
                  cardIcons: widget.cardIcons,
                  itemMap: widget.itemMap,
                  itemLists: widget.itemLists,
                  onNavigateToItem: widget.onNavigateToItem,
                  isExpanded: widget.expandedItemId == widget.items[index].id,
                  isNavigated: widget.navigatedItemId == widget.items[index].id,
                ),
              ),
          ],
        ),
      ),
    );
  }
}