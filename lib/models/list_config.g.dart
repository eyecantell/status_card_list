// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ListConfigImpl _$$ListConfigImplFromJson(Map<String, dynamic> json) =>
    _$ListConfigImpl(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      swipeActions: Map<String, String>.from(json['swipeActions'] as Map),
      buttons: Map<String, String>.from(json['buttons'] as Map),
      dueDateLabel: json['dueDateLabel'] as String? ?? 'Due Date',
      sortMode:
          $enumDecodeNullable(_$SortModeEnumMap, json['sortMode']) ??
          SortMode.dateAscending,
      iconName: json['iconName'] as String? ?? 'list',
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF2196F3,
      cardIcons:
          json['cardIcons'] == null
              ? const []
              : const CardIconListConverter().fromJson(
                json['cardIcons'] as List,
              ),
    );

Map<String, dynamic> _$$ListConfigImplToJson(_$ListConfigImpl instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'name': instance.name,
      'swipeActions': instance.swipeActions,
      'buttons': instance.buttons,
      'dueDateLabel': instance.dueDateLabel,
      'sortMode': _$SortModeEnumMap[instance.sortMode]!,
      'iconName': instance.iconName,
      'colorValue': instance.colorValue,
      'cardIcons': const CardIconListConverter().toJson(instance.cardIcons),
    };

const _$SortModeEnumMap = {
  SortMode.dateAscending: 'dateAscending',
  SortMode.dateDescending: 'dateDescending',
  SortMode.title: 'title',
  SortMode.manual: 'manual',
};

_$CardIconEntryImpl _$$CardIconEntryImplFromJson(Map<String, dynamic> json) =>
    _$CardIconEntryImpl(
      iconName: json['iconName'] as String,
      targetListId: json['targetListId'] as String,
    );

Map<String, dynamic> _$$CardIconEntryImplToJson(_$CardIconEntryImpl instance) =>
    <String, dynamic>{
      'iconName': instance.iconName,
      'targetListId': instance.targetListId,
    };
