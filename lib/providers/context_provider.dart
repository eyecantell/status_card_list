import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_source/multi_context_data_source.dart';
import 'data_source_provider.dart';
import 'items_provider.dart';
import 'lists_provider.dart';
import 'navigation_provider.dart';

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

/// Resets all context-dependent state after switching data source contexts.
/// Must be called AFTER [MultiContextDataSource.switchContext] completes.
/// [defaultListId] is the new context's default list ID (from the data source).
///
/// This is the canonical list of providers that must be reset on context switch.
/// Consuming apps should call this instead of manually resetting individual providers.
void resetContextState(WidgetRef ref, {required String defaultListId}) {
  // 1. Set new default list
  ref.read(currentListIdProvider.notifier).state = defaultListId;
  // 2. Bump context version to force currentContextProvider rebuild
  ref.read(contextVersion.notifier).state++;
  // 3. Clear stale item state
  ref.read(itemCacheProvider.notifier).state = {};
  ref.read(itemToListIndexProvider.notifier).state = {};
  // 4. Clear navigation and search state
  ref.read(expandedItemIdProvider.notifier).state = null;
  ref.read(navigatedItemIdProvider.notifier).state = null;
  ref.read(pendingScrollItemIdProvider.notifier).state = null;
  ref.read(searchQueryProvider.notifier).state = null;
  // 5. Invalidate async providers to refetch for new context
  ref.invalidate(listConfigsProvider);
  ref.invalidate(itemsProvider);
  ref.invalidate(listCountsProvider);
  ref.invalidate(dataContextsProvider);
}
