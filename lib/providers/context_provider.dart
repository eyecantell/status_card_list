import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_source/multi_context_data_source.dart';
import 'data_source_provider.dart';

final dataContextsProvider = FutureProvider<List<DataContext>>((ref) async {
  final ds = ref.read(dataSourceProvider);
  return ds is MultiContextDataSource ? await ds.loadContexts() : [];
});

final currentContextProvider = Provider<DataContext?>((ref) {
  ref.watch(dataContextsProvider); // rebuild when contexts are reloaded (e.g. after switchContext)
  final ds = ref.read(dataSourceProvider);
  return ds is MultiContextDataSource ? ds.currentContext : null;
});
