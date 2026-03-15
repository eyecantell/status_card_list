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
Future<void> navigateToItem(WidgetRef ref, String targetListId, String itemId) async {
  // Capture provider references BEFORE setting state. Setting expandedItemId
  // causes widget rebuilds which may dispose the calling widget (e.g.,
  // RelatedItemsSection inside the previously expanded card). A disposed
  // WidgetRef can't reliably read providers, so we grab what we need upfront.
  final listIdNotifier = ref.read(currentListIdProvider.notifier);
  final expandedNotifier = ref.read(expandedItemIdProvider.notifier);
  final navigatedNotifier = ref.read(navigatedItemIdProvider.notifier);
  final scrollNotifier = ref.read(pendingScrollItemIdProvider.notifier);
  final items = ref.read(itemsProvider.notifier);
  final actions = ref.read(actionsProvider);

  // 1. Set UI intent state first
  listIdNotifier.state = targetListId;
  expandedNotifier.state = itemId;
  navigatedNotifier.state = itemId;

  try {
    // 2. Await data loads so items and detail are ready before scroll/highlight
    await items.refresh();
    final detail = await actions.loadItemDetail(itemId);

    // 2b. If the target item isn't on the loaded page (pagination), inject it
    // so it appears in the list and can be scrolled to / expanded.
    if (!items.containsItem(itemId)) {
      items.injectItem(detail);
    }

    // 3. Signal scroll now that items are loaded (HomeScreen listens and scrolls)
    scrollNotifier.state = itemId;

    // 4. Clear highlight after 2 seconds (starts after data is loaded)
    Future.delayed(const Duration(seconds: 2), () {
      if (navigatedNotifier.state == itemId) {
        navigatedNotifier.state = null;
      }
    });
  } catch (_) {
    // On failure, clear navigation state so the user isn't stuck
    expandedNotifier.state = null;
    navigatedNotifier.state = null;
    scrollNotifier.state = null;
  }
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
