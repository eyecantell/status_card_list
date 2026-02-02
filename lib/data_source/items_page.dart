import '../models/item.dart';

class ItemsPage {
  final List<Item> items;
  final int totalCount;
  final bool hasMore;
  final int offset;

  const ItemsPage({
    required this.items,
    required this.totalCount,
    this.hasMore = false,
    this.offset = 0,
  });
}
