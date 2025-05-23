import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:status_card_list/app.dart'; // Updated import

void main() {
  testWidgets('StatusCardList renders items and switches lists correctly', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify initial list (Review) with 3 items
    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsOneWidget);
    expect(find.text('Prepare Presentation'), findsOneWidget);
    expect(find.text('Review List'), findsOneWidget);

    // Open drawer and switch to Saved list
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved (1)'));
    await tester.pumpAndSettle();

    // Verify Saved list with 1 item
    expect(find.text('Client Meeting Notes'), findsOneWidget);
    expect(find.text('Task 1'), findsNothing);
    expect(find.text('Saved List'), findsOneWidget);

    // Switch to Trash list
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trash (1)'));
    await tester.pumpAndSettle();

    // Verify Trash list with 1 item
    expect(find.text('Old Draft'), findsOneWidget);
    expect(find.text('Client Meeting Notes'), findsNothing);
    expect(find.text('Trash List'), findsOneWidget);
  });
}