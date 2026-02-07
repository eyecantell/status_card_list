import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/constants.dart';

part 'list_config.freezed.dart';
part 'list_config.g.dart';

@freezed
class ListConfig with _$ListConfig {
  const factory ListConfig({
    required String uuid,
    required String name,
    required Map<String, String> swipeActions,
    required Map<String, String> buttons,
    @Default('Due Date') String dueDateLabel,
    @JsonKey(name: 'sort_mode') @Default('manual') String sortMode,
    @Default('list') String iconName,
    @Default(0xFF2196F3) int colorValue,
    @CardIconListConverter() @Default([]) List<CardIconEntry> cardIcons,
  }) = _ListConfig;

  const ListConfig._();

  factory ListConfig.fromJson(Map<String, dynamic> json) =>
      _$ListConfigFromJson(json);

  /// Get the IconData for this list's icon
  IconData get icon => iconMapForLists[iconName] ?? Icons.list;

  /// Get the Color for this list
  Color get color => Color(colorValue);
}

@freezed
class CardIconEntry with _$CardIconEntry {
  const factory CardIconEntry({
    required String iconName,
    required String targetListId,
  }) = _CardIconEntry;

  factory CardIconEntry.fromJson(Map<String, dynamic> json) =>
      _$CardIconEntryFromJson(json);
}

/// Custom converter for cardIcons field to handle legacy array format
class CardIconListConverter
    implements JsonConverter<List<CardIconEntry>, List<dynamic>> {
  const CardIconListConverter();

  @override
  List<CardIconEntry> fromJson(List<dynamic> json) {
    return json.map((item) {
      if (item is List) {
        // Legacy format: ["check_circle", "uuid"]
        return CardIconEntry(
          iconName: item[0] as String,
          targetListId: item[1] as String,
        );
      } else {
        // New format: {"iconName": "check_circle", "targetListId": "uuid"}
        return CardIconEntry.fromJson(item as Map<String, dynamic>);
      }
    }).toList();
  }

  @override
  List<dynamic> toJson(List<CardIconEntry> object) {
    return object.map((e) => e.toJson()).toList();
  }
}

/// Custom converter for color field to handle hex string format
class ColorConverter implements JsonConverter<int, dynamic> {
  const ColorConverter();

  @override
  int fromJson(dynamic json) {
    if (json is int) return json;
    if (json is String) {
      String hexStr = json;
      if (hexStr.startsWith('#')) {
        hexStr = '0xFF${hexStr.substring(1)}';
      } else if (!hexStr.startsWith('0x')) {
        hexStr = '0xFF$hexStr';
      }
      return int.parse(hexStr);
    }
    return 0xFF2196F3; // Default blue
  }

  @override
  String toJson(int object) {
    return '0x${object.toRadixString(16).padLeft(8, '0')}';
  }
}
