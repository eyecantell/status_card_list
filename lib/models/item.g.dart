// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemImpl _$$ItemImplFromJson(Map<String, dynamic> json) => _$ItemImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  subtitle: json['subtitle'] as String,
  html: json['html'] as String?,
  dueDate:
      json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
  status: json['status'] as String,
  relatedItemIds:
      (json['relatedItemIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  extra: json['extra'] as Map<String, dynamic>? ?? const {},
  movedAt:
      json['movedAt'] == null
          ? null
          : DateTime.parse(json['movedAt'] as String),
);

Map<String, dynamic> _$$ItemImplToJson(_$ItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'html': instance.html,
      'dueDate': instance.dueDate?.toIso8601String(),
      'status': instance.status,
      'relatedItemIds': instance.relatedItemIds,
      'extra': instance.extra,
      'movedAt': instance.movedAt?.toIso8601String(),
    };
