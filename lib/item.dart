class Item {
  final String id;
  final String title;
  final String subtitle;
  final String html;
  String status;
  DateTime dueDate;

  Item({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.html,
    required this.dueDate,
    this.status = 'pending',
  });
}