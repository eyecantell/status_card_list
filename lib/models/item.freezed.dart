// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Item _$ItemFromJson(Map<String, dynamic> json) {
  return _Item.fromJson(json);
}

/// @nodoc
mixin _$Item {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get subtitle => throw _privateConstructorUsedError;
  String? get html => throw _privateConstructorUsedError;
  DateTime? get dueDate => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  List<String> get relatedItemIds => throw _privateConstructorUsedError;
  Map<String, dynamic> get extra => throw _privateConstructorUsedError;
  DateTime? get movedAt => throw _privateConstructorUsedError;

  /// Serializes this Item to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemCopyWith<Item> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemCopyWith<$Res> {
  factory $ItemCopyWith(Item value, $Res Function(Item) then) =
      _$ItemCopyWithImpl<$Res, Item>;
  @useResult
  $Res call({
    String id,
    String title,
    String subtitle,
    String? html,
    DateTime? dueDate,
    String status,
    List<String> relatedItemIds,
    Map<String, dynamic> extra,
    DateTime? movedAt,
  });
}

/// @nodoc
class _$ItemCopyWithImpl<$Res, $Val extends Item>
    implements $ItemCopyWith<$Res> {
  _$ItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? subtitle = null,
    Object? html = freezed,
    Object? dueDate = freezed,
    Object? status = null,
    Object? relatedItemIds = null,
    Object? extra = null,
    Object? movedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            subtitle:
                null == subtitle
                    ? _value.subtitle
                    : subtitle // ignore: cast_nullable_to_non_nullable
                        as String,
            html:
                freezed == html
                    ? _value.html
                    : html // ignore: cast_nullable_to_non_nullable
                        as String?,
            dueDate:
                freezed == dueDate
                    ? _value.dueDate
                    : dueDate // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            status:
                null == status
                    ? _value.status
                    : status // ignore: cast_nullable_to_non_nullable
                        as String,
            relatedItemIds:
                null == relatedItemIds
                    ? _value.relatedItemIds
                    : relatedItemIds // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            extra:
                null == extra
                    ? _value.extra
                    : extra // ignore: cast_nullable_to_non_nullable
                        as Map<String, dynamic>,
            movedAt:
                freezed == movedAt
                    ? _value.movedAt
                    : movedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItemImplCopyWith<$Res> implements $ItemCopyWith<$Res> {
  factory _$$ItemImplCopyWith(
    _$ItemImpl value,
    $Res Function(_$ItemImpl) then,
  ) = __$$ItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String subtitle,
    String? html,
    DateTime? dueDate,
    String status,
    List<String> relatedItemIds,
    Map<String, dynamic> extra,
    DateTime? movedAt,
  });
}

/// @nodoc
class __$$ItemImplCopyWithImpl<$Res>
    extends _$ItemCopyWithImpl<$Res, _$ItemImpl>
    implements _$$ItemImplCopyWith<$Res> {
  __$$ItemImplCopyWithImpl(_$ItemImpl _value, $Res Function(_$ItemImpl) _then)
    : super(_value, _then);

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? subtitle = null,
    Object? html = freezed,
    Object? dueDate = freezed,
    Object? status = null,
    Object? relatedItemIds = null,
    Object? extra = null,
    Object? movedAt = freezed,
  }) {
    return _then(
      _$ItemImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        subtitle:
            null == subtitle
                ? _value.subtitle
                : subtitle // ignore: cast_nullable_to_non_nullable
                    as String,
        html:
            freezed == html
                ? _value.html
                : html // ignore: cast_nullable_to_non_nullable
                    as String?,
        dueDate:
            freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        status:
            null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                    as String,
        relatedItemIds:
            null == relatedItemIds
                ? _value._relatedItemIds
                : relatedItemIds // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        extra:
            null == extra
                ? _value._extra
                : extra // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>,
        movedAt:
            freezed == movedAt
                ? _value.movedAt
                : movedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemImpl extends _Item {
  const _$ItemImpl({
    required this.id,
    required this.title,
    required this.subtitle,
    this.html,
    this.dueDate,
    required this.status,
    final List<String> relatedItemIds = const [],
    final Map<String, dynamic> extra = const {},
    this.movedAt,
  }) : _relatedItemIds = relatedItemIds,
       _extra = extra,
       super._();

  factory _$ItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String subtitle;
  @override
  final String? html;
  @override
  final DateTime? dueDate;
  @override
  final String status;
  final List<String> _relatedItemIds;
  @override
  @JsonKey()
  List<String> get relatedItemIds {
    if (_relatedItemIds is EqualUnmodifiableListView) return _relatedItemIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_relatedItemIds);
  }

  final Map<String, dynamic> _extra;
  @override
  @JsonKey()
  Map<String, dynamic> get extra {
    if (_extra is EqualUnmodifiableMapView) return _extra;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_extra);
  }

  @override
  final DateTime? movedAt;

  @override
  String toString() {
    return 'Item(id: $id, title: $title, subtitle: $subtitle, html: $html, dueDate: $dueDate, status: $status, relatedItemIds: $relatedItemIds, extra: $extra, movedAt: $movedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.html, html) || other.html == html) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(
              other._relatedItemIds,
              _relatedItemIds,
            ) &&
            const DeepCollectionEquality().equals(other._extra, _extra) &&
            (identical(other.movedAt, movedAt) || other.movedAt == movedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    subtitle,
    html,
    dueDate,
    status,
    const DeepCollectionEquality().hash(_relatedItemIds),
    const DeepCollectionEquality().hash(_extra),
    movedAt,
  );

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemImplCopyWith<_$ItemImpl> get copyWith =>
      __$$ItemImplCopyWithImpl<_$ItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemImplToJson(this);
  }
}

abstract class _Item extends Item {
  const factory _Item({
    required final String id,
    required final String title,
    required final String subtitle,
    final String? html,
    final DateTime? dueDate,
    required final String status,
    final List<String> relatedItemIds,
    final Map<String, dynamic> extra,
    final DateTime? movedAt,
  }) = _$ItemImpl;
  const _Item._() : super._();

  factory _Item.fromJson(Map<String, dynamic> json) = _$ItemImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get subtitle;
  @override
  String? get html;
  @override
  DateTime? get dueDate;
  @override
  String get status;
  @override
  List<String> get relatedItemIds;
  @override
  Map<String, dynamic> get extra;
  @override
  DateTime? get movedAt;

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemImplCopyWith<_$ItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
