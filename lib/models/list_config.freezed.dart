// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ListConfig _$ListConfigFromJson(Map<String, dynamic> json) {
  return _ListConfig.fromJson(json);
}

/// @nodoc
mixin _$ListConfig {
  String get uuid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  Map<String, String> get swipeActions => throw _privateConstructorUsedError;
  Map<String, String> get buttons => throw _privateConstructorUsedError;
  String get dueDateLabel => throw _privateConstructorUsedError;
  SortMode get sortMode => throw _privateConstructorUsedError;
  String get iconName => throw _privateConstructorUsedError;
  int get colorValue => throw _privateConstructorUsedError;
  @CardIconListConverter()
  List<CardIconEntry> get cardIcons => throw _privateConstructorUsedError;

  /// Serializes this ListConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ListConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ListConfigCopyWith<ListConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ListConfigCopyWith<$Res> {
  factory $ListConfigCopyWith(
    ListConfig value,
    $Res Function(ListConfig) then,
  ) = _$ListConfigCopyWithImpl<$Res, ListConfig>;
  @useResult
  $Res call({
    String uuid,
    String name,
    Map<String, String> swipeActions,
    Map<String, String> buttons,
    String dueDateLabel,
    SortMode sortMode,
    String iconName,
    int colorValue,
    @CardIconListConverter() List<CardIconEntry> cardIcons,
  });
}

/// @nodoc
class _$ListConfigCopyWithImpl<$Res, $Val extends ListConfig>
    implements $ListConfigCopyWith<$Res> {
  _$ListConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ListConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uuid = null,
    Object? name = null,
    Object? swipeActions = null,
    Object? buttons = null,
    Object? dueDateLabel = null,
    Object? sortMode = null,
    Object? iconName = null,
    Object? colorValue = null,
    Object? cardIcons = null,
  }) {
    return _then(
      _value.copyWith(
            uuid:
                null == uuid
                    ? _value.uuid
                    : uuid // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            swipeActions:
                null == swipeActions
                    ? _value.swipeActions
                    : swipeActions // ignore: cast_nullable_to_non_nullable
                        as Map<String, String>,
            buttons:
                null == buttons
                    ? _value.buttons
                    : buttons // ignore: cast_nullable_to_non_nullable
                        as Map<String, String>,
            dueDateLabel:
                null == dueDateLabel
                    ? _value.dueDateLabel
                    : dueDateLabel // ignore: cast_nullable_to_non_nullable
                        as String,
            sortMode:
                null == sortMode
                    ? _value.sortMode
                    : sortMode // ignore: cast_nullable_to_non_nullable
                        as SortMode,
            iconName:
                null == iconName
                    ? _value.iconName
                    : iconName // ignore: cast_nullable_to_non_nullable
                        as String,
            colorValue:
                null == colorValue
                    ? _value.colorValue
                    : colorValue // ignore: cast_nullable_to_non_nullable
                        as int,
            cardIcons:
                null == cardIcons
                    ? _value.cardIcons
                    : cardIcons // ignore: cast_nullable_to_non_nullable
                        as List<CardIconEntry>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ListConfigImplCopyWith<$Res>
    implements $ListConfigCopyWith<$Res> {
  factory _$$ListConfigImplCopyWith(
    _$ListConfigImpl value,
    $Res Function(_$ListConfigImpl) then,
  ) = __$$ListConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uuid,
    String name,
    Map<String, String> swipeActions,
    Map<String, String> buttons,
    String dueDateLabel,
    SortMode sortMode,
    String iconName,
    int colorValue,
    @CardIconListConverter() List<CardIconEntry> cardIcons,
  });
}

/// @nodoc
class __$$ListConfigImplCopyWithImpl<$Res>
    extends _$ListConfigCopyWithImpl<$Res, _$ListConfigImpl>
    implements _$$ListConfigImplCopyWith<$Res> {
  __$$ListConfigImplCopyWithImpl(
    _$ListConfigImpl _value,
    $Res Function(_$ListConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ListConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uuid = null,
    Object? name = null,
    Object? swipeActions = null,
    Object? buttons = null,
    Object? dueDateLabel = null,
    Object? sortMode = null,
    Object? iconName = null,
    Object? colorValue = null,
    Object? cardIcons = null,
  }) {
    return _then(
      _$ListConfigImpl(
        uuid:
            null == uuid
                ? _value.uuid
                : uuid // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        swipeActions:
            null == swipeActions
                ? _value._swipeActions
                : swipeActions // ignore: cast_nullable_to_non_nullable
                    as Map<String, String>,
        buttons:
            null == buttons
                ? _value._buttons
                : buttons // ignore: cast_nullable_to_non_nullable
                    as Map<String, String>,
        dueDateLabel:
            null == dueDateLabel
                ? _value.dueDateLabel
                : dueDateLabel // ignore: cast_nullable_to_non_nullable
                    as String,
        sortMode:
            null == sortMode
                ? _value.sortMode
                : sortMode // ignore: cast_nullable_to_non_nullable
                    as SortMode,
        iconName:
            null == iconName
                ? _value.iconName
                : iconName // ignore: cast_nullable_to_non_nullable
                    as String,
        colorValue:
            null == colorValue
                ? _value.colorValue
                : colorValue // ignore: cast_nullable_to_non_nullable
                    as int,
        cardIcons:
            null == cardIcons
                ? _value._cardIcons
                : cardIcons // ignore: cast_nullable_to_non_nullable
                    as List<CardIconEntry>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ListConfigImpl extends _ListConfig {
  const _$ListConfigImpl({
    required this.uuid,
    required this.name,
    required final Map<String, String> swipeActions,
    required final Map<String, String> buttons,
    this.dueDateLabel = 'Due Date',
    this.sortMode = SortMode.dateAscending,
    this.iconName = 'list',
    this.colorValue = 0xFF2196F3,
    @CardIconListConverter() final List<CardIconEntry> cardIcons = const [],
  }) : _swipeActions = swipeActions,
       _buttons = buttons,
       _cardIcons = cardIcons,
       super._();

  factory _$ListConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ListConfigImplFromJson(json);

  @override
  final String uuid;
  @override
  final String name;
  final Map<String, String> _swipeActions;
  @override
  Map<String, String> get swipeActions {
    if (_swipeActions is EqualUnmodifiableMapView) return _swipeActions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_swipeActions);
  }

  final Map<String, String> _buttons;
  @override
  Map<String, String> get buttons {
    if (_buttons is EqualUnmodifiableMapView) return _buttons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_buttons);
  }

  @override
  @JsonKey()
  final String dueDateLabel;
  @override
  @JsonKey()
  final SortMode sortMode;
  @override
  @JsonKey()
  final String iconName;
  @override
  @JsonKey()
  final int colorValue;
  final List<CardIconEntry> _cardIcons;
  @override
  @JsonKey()
  @CardIconListConverter()
  List<CardIconEntry> get cardIcons {
    if (_cardIcons is EqualUnmodifiableListView) return _cardIcons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cardIcons);
  }

  @override
  String toString() {
    return 'ListConfig(uuid: $uuid, name: $name, swipeActions: $swipeActions, buttons: $buttons, dueDateLabel: $dueDateLabel, sortMode: $sortMode, iconName: $iconName, colorValue: $colorValue, cardIcons: $cardIcons)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ListConfigImpl &&
            (identical(other.uuid, uuid) || other.uuid == uuid) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(
              other._swipeActions,
              _swipeActions,
            ) &&
            const DeepCollectionEquality().equals(other._buttons, _buttons) &&
            (identical(other.dueDateLabel, dueDateLabel) ||
                other.dueDateLabel == dueDateLabel) &&
            (identical(other.sortMode, sortMode) ||
                other.sortMode == sortMode) &&
            (identical(other.iconName, iconName) ||
                other.iconName == iconName) &&
            (identical(other.colorValue, colorValue) ||
                other.colorValue == colorValue) &&
            const DeepCollectionEquality().equals(
              other._cardIcons,
              _cardIcons,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    uuid,
    name,
    const DeepCollectionEquality().hash(_swipeActions),
    const DeepCollectionEquality().hash(_buttons),
    dueDateLabel,
    sortMode,
    iconName,
    colorValue,
    const DeepCollectionEquality().hash(_cardIcons),
  );

  /// Create a copy of ListConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ListConfigImplCopyWith<_$ListConfigImpl> get copyWith =>
      __$$ListConfigImplCopyWithImpl<_$ListConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ListConfigImplToJson(this);
  }
}

abstract class _ListConfig extends ListConfig {
  const factory _ListConfig({
    required final String uuid,
    required final String name,
    required final Map<String, String> swipeActions,
    required final Map<String, String> buttons,
    final String dueDateLabel,
    final SortMode sortMode,
    final String iconName,
    final int colorValue,
    @CardIconListConverter() final List<CardIconEntry> cardIcons,
  }) = _$ListConfigImpl;
  const _ListConfig._() : super._();

  factory _ListConfig.fromJson(Map<String, dynamic> json) =
      _$ListConfigImpl.fromJson;

  @override
  String get uuid;
  @override
  String get name;
  @override
  Map<String, String> get swipeActions;
  @override
  Map<String, String> get buttons;
  @override
  String get dueDateLabel;
  @override
  SortMode get sortMode;
  @override
  String get iconName;
  @override
  int get colorValue;
  @override
  @CardIconListConverter()
  List<CardIconEntry> get cardIcons;

  /// Create a copy of ListConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ListConfigImplCopyWith<_$ListConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CardIconEntry _$CardIconEntryFromJson(Map<String, dynamic> json) {
  return _CardIconEntry.fromJson(json);
}

/// @nodoc
mixin _$CardIconEntry {
  String get iconName => throw _privateConstructorUsedError;
  String get targetListId => throw _privateConstructorUsedError;

  /// Serializes this CardIconEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CardIconEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CardIconEntryCopyWith<CardIconEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CardIconEntryCopyWith<$Res> {
  factory $CardIconEntryCopyWith(
    CardIconEntry value,
    $Res Function(CardIconEntry) then,
  ) = _$CardIconEntryCopyWithImpl<$Res, CardIconEntry>;
  @useResult
  $Res call({String iconName, String targetListId});
}

/// @nodoc
class _$CardIconEntryCopyWithImpl<$Res, $Val extends CardIconEntry>
    implements $CardIconEntryCopyWith<$Res> {
  _$CardIconEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CardIconEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? iconName = null, Object? targetListId = null}) {
    return _then(
      _value.copyWith(
            iconName:
                null == iconName
                    ? _value.iconName
                    : iconName // ignore: cast_nullable_to_non_nullable
                        as String,
            targetListId:
                null == targetListId
                    ? _value.targetListId
                    : targetListId // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CardIconEntryImplCopyWith<$Res>
    implements $CardIconEntryCopyWith<$Res> {
  factory _$$CardIconEntryImplCopyWith(
    _$CardIconEntryImpl value,
    $Res Function(_$CardIconEntryImpl) then,
  ) = __$$CardIconEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String iconName, String targetListId});
}

/// @nodoc
class __$$CardIconEntryImplCopyWithImpl<$Res>
    extends _$CardIconEntryCopyWithImpl<$Res, _$CardIconEntryImpl>
    implements _$$CardIconEntryImplCopyWith<$Res> {
  __$$CardIconEntryImplCopyWithImpl(
    _$CardIconEntryImpl _value,
    $Res Function(_$CardIconEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CardIconEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? iconName = null, Object? targetListId = null}) {
    return _then(
      _$CardIconEntryImpl(
        iconName:
            null == iconName
                ? _value.iconName
                : iconName // ignore: cast_nullable_to_non_nullable
                    as String,
        targetListId:
            null == targetListId
                ? _value.targetListId
                : targetListId // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CardIconEntryImpl implements _CardIconEntry {
  const _$CardIconEntryImpl({
    required this.iconName,
    required this.targetListId,
  });

  factory _$CardIconEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CardIconEntryImplFromJson(json);

  @override
  final String iconName;
  @override
  final String targetListId;

  @override
  String toString() {
    return 'CardIconEntry(iconName: $iconName, targetListId: $targetListId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CardIconEntryImpl &&
            (identical(other.iconName, iconName) ||
                other.iconName == iconName) &&
            (identical(other.targetListId, targetListId) ||
                other.targetListId == targetListId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, iconName, targetListId);

  /// Create a copy of CardIconEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CardIconEntryImplCopyWith<_$CardIconEntryImpl> get copyWith =>
      __$$CardIconEntryImplCopyWithImpl<_$CardIconEntryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CardIconEntryImplToJson(this);
  }
}

abstract class _CardIconEntry implements CardIconEntry {
  const factory _CardIconEntry({
    required final String iconName,
    required final String targetListId,
  }) = _$CardIconEntryImpl;

  factory _CardIconEntry.fromJson(Map<String, dynamic> json) =
      _$CardIconEntryImpl.fromJson;

  @override
  String get iconName;
  @override
  String get targetListId;

  /// Create a copy of CardIconEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CardIconEntryImplCopyWith<_$CardIconEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
