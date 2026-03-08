import 'package:flutter/material.dart';
import 'item.dart';
import 'list_config.dart';
import 'sort_option.dart';

/// Configuration for customizing card rendering.
/// Consumers provide builder callbacks to override default card content.
class CardListConfig {
  /// Build collapsed card content. Receives item + current list config.
  /// If null, default rendering: title, status, due date.
  final Widget Function(BuildContext context, Item item, ListConfig listConfig)? collapsedBuilder;

  /// Build expanded card detail. Receives item + loading flag (true if html still loading).
  /// If null, default rendering: related items + Html widget.
  final Widget Function(BuildContext context, Item item, bool isLoading)? expandedBuilder;

  /// Build trailing widget on collapsed card (e.g., score badge).
  /// If null, no trailing widget.
  final Widget Function(BuildContext context, Item item)? trailingBuilder;

  /// Build subtitle line(s). If null, default: "Status: X, N related items".
  final Widget Function(BuildContext context, Item item)? subtitleBuilder;

  /// Extra widgets to show in the navigation drawer (after list items, before theme toggle).
  final List<Widget>? drawerItems;

  /// Custom drawer header widget. If null, uses default "Task Lists" header.
  final Widget? drawerHeader;

  /// Sort options shown in the sort dropdown. If null, uses SortOption.defaults.
  final List<SortOption>? sortOptions;

  /// Called when user selects a different context in the drawer dropdown.
  /// When provided, the library delegates all provider mutations to the app.
  /// When null, the library handles context switching internally.
  final Future<void> Function(String contextId)? onContextChanged;

  /// Build extra AppBar action widgets. Receives current list ID.
  /// Rendered before the sort button in the AppBar actions list.
  final List<Widget> Function(BuildContext context, String listId)? appBarActionsBuilder;

  /// Whether to show the search icon in the AppBar. Defaults to false.
  final bool searchEnabled;

  /// Build empty state widget when list has no items (and not in search mode).
  /// Receives current list config, all list configs, and per-list counts.
  final Widget Function(
    BuildContext context,
    ListConfig currentList,
    List<ListConfig> allLists,
    Map<String, int> counts,
  )? emptyStateBuilder;

  /// Called when the user taps "New list" in the drawer or popup menu.
  final VoidCallback? onCreateList;

  /// Build compact card for kanban view. Receives item + current list config.
  /// If null, default kanban card rendering is used.
  final Widget Function(BuildContext context, Item item, ListConfig listConfig)? compactCardBuilder;

  /// Called when the user confirms deletion of a list.
  final Function(String listId)? onDeleteList;

  /// Returns true if the given list can be deleted (e.g. not a default list).
  final bool Function(ListConfig)? isListDeletable;

  /// Build extra action widgets for each kanban column header. Receives list ID.
  /// If null, no extra actions are shown in kanban column headers.
  final List<Widget> Function(BuildContext context, String listId)? kanbanColumnActionsBuilder;

  const CardListConfig({
    this.collapsedBuilder,
    this.compactCardBuilder,
    this.expandedBuilder,
    this.trailingBuilder,
    this.subtitleBuilder,
    this.drawerItems,
    this.drawerHeader,
    this.sortOptions,
    this.onContextChanged,
    this.appBarActionsBuilder,
    this.searchEnabled = false,
    this.emptyStateBuilder,
    this.onCreateList,
    this.onDeleteList,
    this.isListDeletable,
    this.kanbanColumnActionsBuilder,
  });
}
