import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/list_config.dart';
import '../models/card_list_config.dart';
import '../utils/constants.dart';

class KanbanCard extends StatelessWidget {
  final Item item;
  final ListConfig listConfig;
  final String listId;
  final List<ListConfig> allConfigs;
  final CardListConfig? cardListConfig;
  final void Function(String itemId, String fromListId, String targetListId)?
      onMove;
  final void Function(String listId, String itemId)? onTap;

  const KanbanCard({
    super.key,
    required this.item,
    required this.listConfig,
    required this.listId,
    required this.allConfigs,
    this.cardListConfig,
    this.onMove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap?.call(listId, item.id),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: listConfig.color, width: 3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cardListConfig?.compactCardBuilder != null
                    ? cardListConfig!.compactCardBuilder!(
                        context, item, listConfig)
                    : _buildDefaultContent(context, isDark),
                if (listConfig.cardIcons.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: _buildActionButtons(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultContent(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        // Subtitle
        Text(
          item.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withAlpha(180),
            fontSize: 11,
          ),
        ),
        if (item.dueDate != null) ...[
          const SizedBox(height: 6),
          _DeadlineBadge(dueDate: item.dueDate!),
        ],
      ],
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final icons = listConfig.cardIcons;
    if (icons.isEmpty) return [];

    return icons.take(3).map((entry) {
      final targetConfig = allConfigs.cast<ListConfig?>().firstWhere(
            (c) => c!.uuid == entry.targetListId,
            orElse: () => null,
          );
      if (targetConfig == null) return const SizedBox.shrink();

      final iconData = iconMap[entry.iconName] ?? Icons.arrow_forward;
      return SizedBox(
        width: 28,
        height: 28,
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 18,
          icon: Icon(iconData, color: targetConfig.color),
          tooltip: targetConfig.name,
          onPressed: () => onMove?.call(item.id, listId, entry.targetListId),
        ),
      );
    }).toList();
  }
}

class _DeadlineBadge extends StatelessWidget {
  final DateTime dueDate;
  const _DeadlineBadge({required this.dueDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;

    final Color bgColor;
    final Color textColor;
    if (diff < 0) {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade900;
    } else if (diff <= 7) {
      bgColor = Colors.amber.shade100;
      textColor = Colors.amber.shade900;
    } else {
      bgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
    }

    final label = '${dueDate.month}/${dueDate.day}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
