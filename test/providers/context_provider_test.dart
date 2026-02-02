import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_card_list/data_source/in_memory_data_source.dart';
import 'package:status_card_list/data_source/multi_context_data_source.dart';
import 'package:status_card_list/providers/context_provider.dart';
import 'package:status_card_list/providers/data_source_provider.dart';

/// Helper to wait for provider to have data
Future<T> waitForData<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final startTime = DateTime.now();
  while (DateTime.now().difference(startTime) < timeout) {
    final state = container.read(provider);
    if (state.hasValue) {
      return state.value as T;
    }
    await Future.delayed(const Duration(milliseconds: 50));
  }
  throw TimeoutException('Waiting for provider data timed out');
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

void main() {
  group('Context providers with InMemoryDataSource (non-multi-context)', () {
    late ProviderContainer container;
    late InMemoryDataSource dataSource;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      dataSource = InMemoryDataSource(prefs);
      await dataSource.initialize();

      container = ProviderContainer(
        overrides: [
          dataSourceProvider.overrideWithValue(dataSource),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('dataContextsProvider returns empty list for non-multi-context datasource', () async {
      final contexts = await waitForData(container, dataContextsProvider);
      expect(contexts, isEmpty);
    });

    test('currentContextProvider returns null for non-multi-context datasource', () {
      final context = container.read(currentContextProvider);
      expect(context, isNull);
    });
  });

  group('DataContext', () {
    test('creates with required fields', () {
      const ctx = DataContext(id: 'ctx-1', name: 'Company A');
      expect(ctx.id, 'ctx-1');
      expect(ctx.name, 'Company A');
      expect(ctx.description, isNull);
    });

    test('creates with optional description', () {
      const ctx = DataContext(
        id: 'ctx-1',
        name: 'Company A',
        description: 'First company',
      );
      expect(ctx.description, 'First company');
    });
  });
}
