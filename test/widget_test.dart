import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:status_card_list/data_source/in_memory_data_source.dart';
import 'package:status_card_list/models/card_list_config.dart';
import 'package:status_card_list/providers/data_source_provider.dart';
import 'package:status_card_list/providers/theme_provider.dart';
import 'package:status_card_list/screens/home_screen.dart';

void main() {
  testWidgets('StatusCardList renders items and switches lists correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dataSource = InMemoryDataSource(prefs);
    await dataSource.initialize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataSourceProvider.overrideWithValue(dataSource),
        ],
        child: MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial list (Review) with 3 items
    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsOneWidget);
    expect(find.text('Prepare Presentation'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);

    // Open drawer and switch to Saved list
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved (1)'));
    await tester.pumpAndSettle();

    // Verify Saved list with 1 item
    expect(find.text('Client Meeting Notes'), findsOneWidget);
    expect(find.text('Task 1'), findsNothing);
    expect(find.text('Saved'), findsOneWidget);

    // Switch to Trash list
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trash (1)'));
    await tester.pumpAndSettle();

    // Verify Trash list with 1 item
    expect(find.text('Old Draft'), findsOneWidget);
    expect(find.text('Client Meeting Notes'), findsNothing);
    expect(find.text('Trash'), findsOneWidget);
  });

  testWidgets('Custom drawerItems render in the navigation drawer', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dataSource = InMemoryDataSource(prefs);
    await dataSource.initialize();

    final config = CardListConfig(
      drawerItems: [
        const ListTile(
          leading: Icon(Icons.help_outline),
          title: Text('How It Works'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataSourceProvider.overrideWithValue(dataSource),
        ],
        child: MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          home: HomeScreen(cardListConfig: config),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Verify custom drawer item is rendered
    expect(find.text('How It Works'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
  });

  testWidgets('Empty drawerItems list produces no extra dividers', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dataSource = InMemoryDataSource(prefs);
    await dataSource.initialize();

    const config = CardListConfig(drawerItems: []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataSourceProvider.overrideWithValue(dataSource),
        ],
        child: MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          home: const HomeScreen(cardListConfig: config),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open drawer
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // Count Dividers — should be exactly 1 (the one between list items and theme toggle)
    expect(find.byType(Divider), findsOneWidget);
  });
}
