import 'package:flutter/material.dart';
import 'models/item.dart';
import 'models/list_config.dart';
import 'models/card_list_config.dart';
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
  final List<CardIconEntry> cardIcons;
  final Map<String, Item> itemMap;
  final Map<String, String> itemToListIndex;
  final Function(String, String) onNavigateToItem;
  final String? expandedItemId;
  final String? navigatedItemId;
  final ScrollController? scrollController;
  final void Function(String itemId)? onExpand;
  final CardListConfig? cardListConfig;

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
    required this.itemToListIndex,
    required this.onNavigateToItem,
    required this.expandedItemId,
    required this.navigatedItemId,
    this.scrollController,
    this.onExpand,
    this.cardListConfig,
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
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
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
                  itemToListIndex: widget.itemToListIndex,
                  onNavigateToItem: widget.onNavigateToItem,
                  isExpanded: widget.expandedItemId == widget.items[index].id,
                  isNavigated: widget.navigatedItemId == widget.items[index].id,
                  onExpand: widget.onExpand,
                  cardListConfig: widget.cardListConfig,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
