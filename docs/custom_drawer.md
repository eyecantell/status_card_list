# Custom Drawer Items

The engine's navigation drawer shows list items and a theme toggle by default. `CardListConfig.drawerItems` lets consumers inject custom widgets between the list items and the theme toggle — useful for help links, external links, or app-specific actions.

## Usage

Pass `drawerItems` when creating your `CardListConfig`:

```dart
HomeScreen(
  cardListConfig: CardListConfig(
    drawerItems: [
      ListTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('How Matching Works'),
        onTap: () {
          Navigator.pop(context); // close drawer first
          showDialog(
            context: context,
            builder: (_) => const AlertDialog(
              title: Text('How Matching Works'),
              content: Text('Your help content here.'),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.open_in_new),
        title: const Text('SAM.gov'),
        onTap: () {
          Navigator.pop(context);
          launchUrl(Uri.parse('https://sam.gov'));
        },
      ),
    ],
  ),
)
```

## Where items appear

```
┌──────────────────────┐
│  Drawer Header       │
├──────────────────────┤
│  List 1 (count)      │
│  List 2 (count)      │
│  List 3 (count)      │
├──── Divider ─────────┤
│  ← your drawerItems  │
├──── Divider ─────────┤
│  Theme toggle        │
└──────────────────────┘
```

The second divider is only rendered when `drawerItems` is non-null and non-empty.

## Context access

Since `drawerItems` may need a `BuildContext` for navigation or dialogs, build the config inside a widget's `build` method using `Builder`:

```dart
home: Builder(
  builder: (context) => HomeScreen(
    cardListConfig: CardListConfig(
      drawerItems: [
        ListTile(
          title: const Text('Help'),
          onTap: () {
            Navigator.pop(context);
            // navigate or show dialog
          },
        ),
      ],
    ),
  ),
),
```

## Behavior

- **null or omitted**: Default drawer with no extra items or dividers
- **Empty list `[]`**: Same as null — no extra dividers rendered
- **Non-empty list**: Items rendered between the list-items divider and a new divider above the theme toggle
- Use `ListTile` for visual consistency with the rest of the drawer
- Always call `Navigator.pop(context)` in `onTap` to close the drawer before performing actions

## Files involved

| File | Role |
|---|---|
| `lib/models/card_list_config.dart` | `drawerItems` field definition |
| `lib/widgets/drawer_menu.dart` | Renders items in the drawer |
| `lib/screens/home_screen.dart` | Passes `drawerItems` from config to drawer |
