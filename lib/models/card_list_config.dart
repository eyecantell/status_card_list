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

  /// Sort options shown in the sort dropdown. If null, uses SortOption.defaults.
  final List<SortOption>? sortOptions;

  const CardListConfig({
    this.collapsedBuilder,
    this.expandedBuilder,
    this.trailingBuilder,
    this.subtitleBuilder,
    this.drawerItems,
    this.sortOptions,
  });
}
