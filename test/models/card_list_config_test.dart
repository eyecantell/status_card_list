import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:status_card_list/models/card_list_config.dart';
import 'package:status_card_list/models/item.dart';
import 'package:status_card_list/models/list_config.dart';
import 'package:status_card_list/models/sort_option.dart';
import 'package:status_card_list/status_card.dart';

void main() {
  group('CardListConfig', () {
    test('creates with all null builders (defaults)', () {
      const config = CardListConfig();
      expect(config.collapsedBuilder, isNull);
      expect(config.expandedBuilder, isNull);
      expect(config.trailingBuilder, isNull);
      expect(config.subtitleBuilder, isNull);
      expect(config.drawerItems, isNull);
      expect(config.sortOptions, isNull);
    });

    test('drawerItems defaults to null', () {
      const config = CardListConfig();
      expect(config.drawerItems, isNull);
    });

    test('drawerItems accepts a list of widgets', () {
      final config = CardListConfig(
        drawerItems: [
          const ListTile(title: Text('Help')),
          const ListTile(title: Text('About')),
        ],
      );
      expect(config.drawerItems, isNotNull);
      expect(config.drawerItems!.length, 2);
    });

    test('drawerItems accepts an empty list', () {
      const config = CardListConfig(drawerItems: []);
      expect(config.drawerItems, isNotNull);
      expect(config.drawerItems!.isEmpty, isTrue);
    });

    test('sortOptions defaults to null', () {
      const config = CardListConfig();
      expect(config.sortOptions, isNull);
    });

    test('sortOptions accepts a list', () {
      final config = CardListConfig(
        sortOptions: [
          SortOption.manual,
          SortOption.byField(id: 'title', label: 'Title', field: (i) => i.title),
        ],
      );
      expect(config.sortOptions, isNotNull);
      expect(config.sortOptions!.length, 2);
    });

    test('sortOptions accepts an empty list', () {
      const config = CardListConfig(sortOptions: []);
      expect(config.sortOptions, isNotNull);
      expect(config.sortOptions!.isEmpty, isTrue);
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

  group('CardListConfig builders wired into StatusCard', () {
    final testItem = Item(
      id: '1',
      title: 'Test Item',
      subtitle: 'Test Subtitle',
      status: 'Open',
    );

    final testListConfig = ListConfig(
      uuid: 'list-1',
      name: 'Test List',
      swipeActions: {},
      buttons: {},
    );

    Widget buildStatusCard({CardListConfig? cardListConfig, bool isExpanded = false}) {
      return MaterialApp(
        home: Scaffold(
          body: StatusCard(
            item: testItem,
            index: 0,
            statusIcons: const {},
            swipeActions: const {},
            onStatusChanged: (_, __) {},
            onReorder: (_, __) {},
            dueDateLabel: 'Deadline',
            listColor: Colors.blue,
            allConfigs: [testListConfig],
            cardIcons: const [],
            itemMap: const {},
            itemToListIndex: const {},
            onNavigateToItem: (_, __) {},
            listConfig: testListConfig,
            isExpanded: isExpanded,
            cardListConfig: cardListConfig,
          ),
        ),
      );
    }

    testWidgets('collapsedBuilder replaces default ListTile when provided', (tester) async {
      final config = CardListConfig(
        collapsedBuilder: (context, item, listConfig) {
          return Text('CUSTOM COLLAPSED: ${item.title} in ${listConfig.name}');
        },
      );

      await tester.pumpWidget(buildStatusCard(cardListConfig: config));
      await tester.pumpAndSettle();

      expect(find.text('CUSTOM COLLAPSED: Test Item in Test List'), findsOneWidget);
      // Default ListTile title should not appear
      expect(find.text('Test Item'), findsNothing);
    });

    testWidgets('subtitleBuilder replaces default subtitle when provided', (tester) async {
      final config = CardListConfig(
        subtitleBuilder: (context, item) {
          return Text('CUSTOM SUBTITLE: ${item.status}');
        },
      );

      await tester.pumpWidget(buildStatusCard(cardListConfig: config));
      await tester.pumpAndSettle();

      expect(find.text('CUSTOM SUBTITLE: Open'), findsOneWidget);
      // Default status line should not appear
      expect(find.textContaining('Status: Open'), findsNothing);
    });

    testWidgets('trailingBuilder adds trailing widget when provided', (tester) async {
      final config = CardListConfig(
        trailingBuilder: (context, item) {
          return const Text('TRAILING');
        },
      );

      await tester.pumpWidget(buildStatusCard(cardListConfig: config));
      await tester.pumpAndSettle();

      expect(find.text('TRAILING'), findsOneWidget);
      // Default title should still be present
      expect(find.text('Test Item'), findsOneWidget);
    });

    testWidgets('default rendering when no builders provided', (tester) async {
      await tester.pumpWidget(buildStatusCard());
      await tester.pumpAndSettle();

      // Default title and status should appear
      expect(find.text('Test Item'), findsOneWidget);
      expect(find.textContaining('Status: Open'), findsOneWidget);
      expect(find.text('No deadline'), findsOneWidget);
    });
  });
}
