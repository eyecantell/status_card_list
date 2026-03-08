import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_source_provider.dart';
import '../providers/items_provider.dart';
import '../providers/lists_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/list_config.dart';

/// A reusable widget that displays related items with navigation support.
///
/// Takes pre-fetched data (not from cache) so titles are always available,
/// even for items on other pages/lists. Uses the item-to-list index for
/// fast lookups, falling back to an API call (findListContainingItem) when
/// the target item isn't in the local index.
class RelatedItemsSection extends ConsumerStatefulWidget {
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
  ConsumerState<RelatedItemsSection> createState() =>
      _RelatedItemsSectionState();
}

class _RelatedItemsSectionState extends ConsumerState<RelatedItemsSection> {
  /// Resolved list IDs for items not in the local index.
  /// Maps itemId → listId (or empty string if not found).
  final Map<String, String> _resolvedListIds = {};

  /// Items currently being resolved via API.
  final Set<String> _resolving = {};

  @override
  void initState() {
    super.initState();
    // Kick off resolution for items not yet in the local index
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveUnknownItems());
  }

  void _resolveUnknownItems() {
    final itemToList = ref.read(itemToListIndexProvider);
    for (final data in widget.relatedNotices) {
      final itemId = data['id']?.toString() ?? '';
      if (itemId.isEmpty) continue;
      if (itemToList.containsKey(itemId)) continue;
      if (_resolvedListIds.containsKey(itemId)) continue;
      _resolveItem(itemId);
    }
  }

  Future<void> _resolveItem(String itemId) async {
    if (_resolving.contains(itemId)) return;
    _resolving.add(itemId);

    try {
      final ds = ref.read(dataSourceProvider);
      final listId = await ds.findListContainingItem(itemId);
      if (mounted) {
        setState(() {
          _resolvedListIds[itemId] = listId ?? '';
        });
        // Also update the shared index so other widgets benefit
        if (listId != null && listId.isNotEmpty) {
          ref.read(itemToListIndexProvider.notifier).update((state) =>
              {...state, itemId: listId});
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedListIds[itemId] = '';
        });
      }
    } finally {
      _resolving.remove(itemId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.relatedNotices.isEmpty) return const SizedBox.shrink();

    final itemToList = ref.watch(itemToListIndexProvider);
    final allConfigs = ref.watch(listConfigsProvider).value ?? [];
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title ?? 'Related Items:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
          ),
          const SizedBox(height: 4),
          ...widget.relatedNotices.map((data) {
            final itemId = data['id']?.toString() ?? '';
            // Check local index first, then fall back to resolved cache
            final targetListId = itemToList[itemId] ??
                _resolvedListIds[itemId] ?? '';

            final targetConfig = allConfigs.cast<ListConfig?>().firstWhere(
                  (c) => c!.uuid == targetListId,
                  orElse: () => null,
                );
            final listName = targetConfig?.name ?? '';
            final canNavigate = targetListId.isNotEmpty;
            final isResolving = _resolving.contains(itemId) &&
                !itemToList.containsKey(itemId) &&
                !_resolvedListIds.containsKey(itemId);

            final label = widget.labelBuilder != null
                ? widget.labelBuilder!(context, data, listName)
                : Text(
                    '${data['title']?.toString() ?? 'Unknown'}'
                    '${listName.isNotEmpty ? ' ($listName)' : ''}',
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
            } else if (isResolving) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    label,
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ),
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
