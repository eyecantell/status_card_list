import 'package:json_annotation/json_annotation.dart';

part 'sort_mode.g.dart';

@JsonEnum(alwaysCreate: true)
enum SortMode {
  dateAscending,
  dateDescending,
  title,
  manual,
  similarityDescending,
  deadlineSoonest,
  newest,
}
