import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_source/card_list_data_source.dart';

/// Provider for the CardListDataSource instance.
/// Must be overridden in ProviderScope at app startup.
final dataSourceProvider = Provider<CardListDataSource>((ref) {
  throw UnimplementedError(
    'dataSourceProvider must be overridden in ProviderScope',
  );
});
