# Card Interactions

This guide covers the built-in gestures and interactions available on cards in the engine.

## Card States

Each card has two states:

- **Collapsed** — shows title, subtitle, status, due date, and action icons
- **Expanded** — shows full detail content (HTML) and related items

Tap a card to toggle between collapsed and expanded. When expanded, the engine calls `loadItemDetail()` to fetch full content if the item's `html` is null.

## Gestures

### Tap

Tap a card to expand it. Tap again to collapse. Only one card can be expanded at a time — expanding a new card collapses the previous one.

### Swipe

Swipe a card left or right to move it to another list. The swipe directions are configured per list via `ListConfig.swipeActions`:

```dart
ListConfig(
  swipeActions: {
    'right': savedListId,   // swipe right → move to Saved
    'left': trashListId,    // swipe left → move to Trash
  },
)
```

After a swipe, a snackbar appears with an **Undo** button (5-second timeout).

### Long Press + Drag (Reorder)

**Long press** a card (hold for ~500ms), then drag to reorder it within the list. This uses Flutter's `ReorderableDelayedDragStartListener` — a quick tap-and-drag won't work, you must hold first.

When you reorder, the sort mode automatically switches to **Manual** to preserve your custom order.

A drag proxy (card title on an elevated surface) appears while dragging.

### Action Icons

Cards display icon buttons configured via `ListConfig.cardIcons`. Tapping an icon moves the item to the associated target list:

```dart
ListConfig(
  cardIcons: [
    CardIconEntry(iconName: 'check_circle', targetListId: savedListId),
    CardIconEntry(iconName: 'delete', targetListId: trashListId),
  ],
)
```

Icons appear in the card's action row. Like swipes, moving via icon shows an undo snackbar.

## Sort Dropdown

The sort icon in the app bar opens a dropdown with the available sort options. See [sorting.md](sorting.md) for details on configuring sort options.

Selecting a sort option reloads the list in that order. The selected sort is persisted per list.

## List Switching

Two ways to switch lists:

- **App bar dropdown** — tap the list name/icon in the app bar to see all lists with counts
- **Navigation drawer** — swipe from the left edge or tap the hamburger menu

Switching lists clears the current expanded card and any snackbars.

## Related Items

When a card is expanded, related items (configured via `Item.relatedItemIds`) appear as tappable chips. Tapping a related item navigates to its list and scrolls to it with a brief highlight animation.

## Undo

Moving an item (via swipe or action icon) shows a floating snackbar:

```
"Task Title moved to Saved"  [Undo]
```

The Undo button moves the item back to the original list. The snackbar auto-dismisses after 5 seconds.
