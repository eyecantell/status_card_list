import 'package:freezed_annotation/freezed_annotation.dart';

part 'item.freezed.dart';
part 'item.g.dart';

@freezed
class Item with _$Item {
  const factory Item({
    required String id,
    required String title,
    required String subtitle,
    required String html,
    required DateTime dueDate,
    required String status,
    @Default([]) List<String> relatedItemIds,
  }) = _Item;

  const Item._();

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  /// Format due date relative to reference (defaults to now)
  String formatDueDateRelative([DateTime? referenceDate]) {
    final reference = referenceDate ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = dueDay.difference(today).inDays;

    final daysText = switch (difference) {
      0 => 'today',
      1 => 'tomorrow',
      -1 => 'yesterday',
      > 0 => 'in $difference days',
      _ => '${-difference} days ago',
    };

    final formatted = '${dueDate.month}/${dueDate.day}/${dueDate.year}';
    return '$formatted ($daysText)';
  }

  bool get isOverdue => dueDate.isBefore(DateTime.now());
}
