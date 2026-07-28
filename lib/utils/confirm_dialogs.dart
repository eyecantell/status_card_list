import 'package:flutter/material.dart';

/// Confirmation dialog for single-item moves into a permanent-delete list.
/// Returns true only when the user explicitly confirms.
Future<bool> confirmPermanentDelete(
  BuildContext context,
  String itemTitle,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Permanently delete?'),
          content: Text(
            '"$itemTitle" will be permanently deleted. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete permanently'),
            ),
          ],
        ),
  );
  return confirmed == true;
}
