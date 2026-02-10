import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_source/multi_context_data_source.dart';
import 'data_source_provider.dart';

final dataContextsProvider = FutureProvider<List<DataContext>>((ref) async {
  final ds = ref.read(dataSourceProvider);
  return ds is MultiContextDataSource ? await ds.loadContexts() : [];
});

/// Incremented on each context switch to force [currentContextProvider] to rebuild.
final contextVersion = StateProvider<int>((ref) => 0);

final currentContextProvider = Provider<DataContext?>((ref) {
  ref.watch(contextVersion); // force rebuild on every context switch
  final ds = ref.read(dataSourceProvider);
  return ds is MultiContextDataSource ? ds.currentContext : null;
});
