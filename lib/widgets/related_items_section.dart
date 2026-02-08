import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/items_provider.dart';
import '../providers/lists_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/list_config.dart';

/// A reusable widget that displays related items with navigation support.
///
/// Takes pre-fetched data (not from cache) so titles are always available,
/// even for items on other pages/lists. Uses the item-to-list index only
/// for navigation (determining which list to switch to).
class RelatedItemsSection extends ConsumerWidget {
  /// Pre-fetched related item data: [{id, title, posted_date}, ...]
  final List<Map<String, dynamic>> relatedNotices;

  /// Optional custom label builder for each related item link.
  /// Receives (context, noticeData, listName) and returns a widget.
  final Widget Function(
    BuildContext context,
    Map<String, dynamic> noticeData,
    String listName,
  )? labelBuilder;

  /// Section title (default: "Related Items:")
  final String? title;

  const RelatedItemsSection({
    super.key,
    required this.relatedNotices,
    this.labelBuilder,
    this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (relatedNotices.isEmpty) return const SizedBox.shrink();

    final itemToList = ref.watch(itemToListIndexProvider);
    final allConfigs = ref.watch(listConfigsProvider).value ?? [];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? 'Related Items:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
          ),
          const SizedBox(height: 4),
          ...relatedNotices.map((data) {
            final itemId = data['id']?.toString() ?? '';
            final itemTitle = data['title']?.toString() ?? 'Unknown';
            final targetListId = itemToList[itemId] ?? '';

            final targetConfig = allConfigs.cast<ListConfig?>().firstWhere(
                  (c) => c!.uuid == targetListId,
                  orElse: () => null,
                );
            final listName = targetConfig?.name ?? '';
            final canNavigate = targetListId.isNotEmpty;

            final label = labelBuilder != null
                ? labelBuilder!(context, data, listName)
                : Text(
                    '$itemTitle${listName.isNotEmpty ? ' ($listName)' : ''}',
                    style: TextStyle(
                      color: canNavigate
                          ? (isDarkMode ? Colors.blue[300] : Colors.blue[700])
                          : null,
                      decoration:
                          canNavigate ? TextDecoration.underline : null,
                    ),
                  );

            if (canNavigate) {
              return TextButton(
                onPressed: () async =>
                    await navigateToItem(ref, targetListId, itemId),
                child: label,
              );
            } else {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: label,
              );
            }
          }),
        ],
      ),
    );
  }
}
