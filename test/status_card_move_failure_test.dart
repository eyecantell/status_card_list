import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:status_card_list/models/item.dart';
import 'package:status_card_list/models/list_config.dart';
import 'package:status_card_list/status_card.dart';

/// Locks the failed-move contract: when onStatusChanged returns false, the
/// card must animate back into place (un-collapse + slide back) instead of
/// staying dismissed — the item is still in the list and this State is reused.
void main() {
  const testItem = Item(
    id: 'item-1',
    title: 'Test Notice',
    subtitle: 'sub',
    status: 'new',
    html: '<p>detail</p>',
  );

  const sourceList = ListConfig(
    uuid: 'list-review',
    name: 'Review',
    swipeActions: {},
    buttons: {},
  );

  const targetList = ListConfig(
    uuid: 'list-saved',
    name: 'Saved',
    swipeActions: {},
    buttons: {},
  );

  Widget buildCard(Future<bool> Function(Item, String) onStatusChanged) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: StatusCard(
            item: testItem,
            index: 0,
            statusIcons: const {},
            swipeActions: const {},
            onStatusChanged: onStatusChanged,
            onReorder: (_, __) {},
            dueDateLabel: 'Deadline',
            listColor: Colors.blue,
            allConfigs: const [sourceList, targetList],
            cardIcons: const [
              CardIconEntry(iconName: 'star', targetListId: 'list-saved'),
            ],
            itemMap: const {},
            itemToListIndex: const {},
            onNavigateToItem: (_, __) {},
            listConfig: sourceList,
          ),
        ),
      ),
    );
  }

  SizeTransition cardSizeTransition(WidgetTester tester) =>
      tester.widget<SizeTransition>(find
          .ancestor(
            of: find.text('Test Notice'),
            matching: find.byType(SizeTransition),
          )
          .first);

  testWidgets('card animates back when the move fails', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(buildCard((item, target) async {
      calls.add(target);
      return false; // move failed
    }));

    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    expect(calls, ['list-saved']);
    // Restored: full height and back at rest (not dismissed off screen).
    expect(cardSizeTransition(tester).sizeFactor.value, 1.0);
    final transform = tester.widget<Transform>(find
        .ancestor(
          of: find.text('Test Notice'),
          matching: find.byType(Transform),
        )
        .first);
    expect(transform.transform.getTranslation().x, 0.0);
  });

  testWidgets('card stays dismissed when the move succeeds', (tester) async {
    await tester.pumpWidget(buildCard((item, target) async => true));

    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    // Collapsed away — in the real app the item is removed from the list and
    // the widget disposed; the State must not resurrect the card itself.
    expect(cardSizeTransition(tester).sizeFactor.value, 0.0);
  });
}
