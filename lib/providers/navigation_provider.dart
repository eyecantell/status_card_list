import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'actions_provider.dart';
import 'items_provider.dart';
import 'lists_provider.dart';

/// Provider for the currently expanded item ID (only one at a time)
final expandedItemIdProvider = StateProvider<String?>((ref) => null);

/// Provider for the navigated item ID (for highlight animation)
final navigatedItemIdProvider = StateProvider<String?>((ref) => null);

/// Provider for the scroll controller
/// Note: The actual ScrollController should be created in the widget tree
/// and passed to the StatusCardList. This provider tracks if we need to scroll.
final pendingScrollItemIdProvider = StateProvider<String?>((ref) => null);

/// Navigate to an item in a specific list
/// This coordinates: list switching, item expansion, highlighting, scrolling,
/// and detail loading.
void navigateToItem(WidgetRef ref, String targetListId, String itemId) {
  // 1. Switch to target list
  ref.read(currentListIdProvider.notifier).state = targetListId;

  // 1b. Refresh items for the new list
  ref.read(itemsProvider.notifier).refresh();

  // 2. Expand the item
  ref.read(expandedItemIdProvider.notifier).state = itemId;

  // 3. Set navigated item for highlight effect
  ref.read(navigatedItemIdProvider.notifier).state = itemId;

  // 4. Set pending scroll target
  ref.read(pendingScrollItemIdProvider.notifier).state = itemId;

  // 5. Load item detail (so expanded content populates)
  ref.read(actionsProvider).loadItemDetail(itemId);

  // 6. Clear highlight after 2 seconds
  Future.delayed(const Duration(seconds: 2), () {
    if (ref.read(navigatedItemIdProvider) == itemId) {
      ref.read(navigatedItemIdProvider.notifier).state = null;
    }
  });
}

/// Clear the pending scroll after scrolling is complete
void clearPendingScroll(WidgetRef ref) {
  ref.read(pendingScrollItemIdProvider.notifier).state = null;
}

/// Toggle expanded state for an item
void toggleExpanded(WidgetRef ref, String itemId) {
  final current = ref.read(expandedItemIdProvider);
  ref.read(expandedItemIdProvider.notifier).state =
      current == itemId ? null : itemId;
}

/// Collapse all expanded items
void collapseAll(WidgetRef ref) {
  ref.read(expandedItemIdProvider.notifier).state = null;
}

/// Card height constants for scroll offset calculation
class CardDimensions {
  /// Approximate height of a collapsed card
  static const double collapsedHeight = 165.0;

  /// Additional height when card is expanded
  static const double expandedExtra = 135.0;

  /// Calculate scroll offset for an item at a given index
  static double calculateScrollOffset(int index, {bool isExpanded = false}) {
    double offset = index * collapsedHeight;
    if (isExpanded) {
      offset += expandedExtra;
    }
    return offset;
  }
}
