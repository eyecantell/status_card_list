import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:status_card_list/models/card_list_config.dart';
import 'package:status_card_list/models/item.dart';
import 'package:status_card_list/models/list_config.dart';

void main() {
  group('CardListConfig', () {
    test('creates with all null builders (defaults)', () {
      const config = CardListConfig();
      expect(config.collapsedBuilder, isNull);
      expect(config.expandedBuilder, isNull);
      expect(config.trailingBuilder, isNull);
      expect(config.subtitleBuilder, isNull);
    });

    test('creates with custom collapsedBuilder', () {
      final config = CardListConfig(
        collapsedBuilder: (context, item, listConfig) {
          return Text(item.title);
        },
      );
      expect(config.collapsedBuilder, isNotNull);
      expect(config.expandedBuilder, isNull);
    });

    test('creates with custom expandedBuilder', () {
      final config = CardListConfig(
        expandedBuilder: (context, item, isLoading) {
          return isLoading
              ? const CircularProgressIndicator()
              : Text(item.html ?? 'No content');
        },
      );
      expect(config.expandedBuilder, isNotNull);
    });

    test('creates with custom trailingBuilder', () {
      final config = CardListConfig(
        trailingBuilder: (context, item) {
          final score = item.extra['score'] as double? ?? 0.0;
          return Text('$score');
        },
      );
      expect(config.trailingBuilder, isNotNull);
    });

    test('creates with custom subtitleBuilder', () {
      final config = CardListConfig(
        subtitleBuilder: (context, item) {
          return Text('Status: ${item.status}');
        },
      );
      expect(config.subtitleBuilder, isNotNull);
    });

    test('creates with all custom builders', () {
      final config = CardListConfig(
        collapsedBuilder: (context, item, listConfig) => Text(item.title),
        expandedBuilder: (context, item, isLoading) => Text(item.html ?? ''),
        trailingBuilder: (context, item) => const Icon(Icons.star),
        subtitleBuilder: (context, item) => Text(item.subtitle),
      );
      expect(config.collapsedBuilder, isNotNull);
      expect(config.expandedBuilder, isNotNull);
      expect(config.trailingBuilder, isNotNull);
      expect(config.subtitleBuilder, isNotNull);
    });

    testWidgets('collapsedBuilder receives correct parameters', (tester) async {
      Item? receivedItem;
      ListConfig? receivedConfig;

      final testItem = Item(
        id: '1',
        title: 'Test Item',
        subtitle: 'Sub',
        status: 'Open',
      );

      final testListConfig = ListConfig(
        uuid: 'list-1',
        name: 'Test List',
        swipeActions: {},
        buttons: {},
      );

      final config = CardListConfig(
        collapsedBuilder: (context, item, listConfig) {
          receivedItem = item;
          receivedConfig = listConfig;
          return Text(item.title);
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return config.collapsedBuilder!(context, testItem, testListConfig);
            },
          ),
        ),
      );

      expect(receivedItem?.id, '1');
      expect(receivedConfig?.name, 'Test List');
      expect(find.text('Test Item'), findsOneWidget);
    });

    testWidgets('expandedBuilder receives loading flag', (tester) async {
      final testItem = Item(
        id: '1',
        title: 'Test',
        subtitle: 'Sub',
        status: 'Open',
      );

      final config = CardListConfig(
        expandedBuilder: (context, item, isLoading) {
          return isLoading
              ? const Text('Loading...')
              : Text(item.html ?? 'No content');
        },
      );

      // Test with isLoading = true
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return config.expandedBuilder!(context, testItem, true);
            },
          ),
        ),
      );
      expect(find.text('Loading...'), findsOneWidget);

      // Test with isLoading = false
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return config.expandedBuilder!(context, testItem, false);
            },
          ),
        ),
      );
      expect(find.text('No content'), findsOneWidget);
    });
  });
}
