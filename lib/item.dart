class Item {
  final String id;
  final String title;
  final String subtitle;
  final String html;
  String status;
  DateTime dueDate;
  final List<String> relatedItemIds; // Added for related items

  Item({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.html,
    required this.dueDate,
    this.status = 'pending',
    this.relatedItemIds = const [], // Default to empty list
  });
}