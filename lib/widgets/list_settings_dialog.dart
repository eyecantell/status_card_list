import 'package:flutter/material.dart';
import '../models/list_config.dart';
import '../utils/constants.dart';

class ListSettingsDialog extends StatefulWidget {
  final ListConfig listConfig;
  final List<ListConfig> allConfigs;
  final Function(ListConfig) onSave;
  final VoidCallback? onDelete;
  final bool isDeletable;

  const ListSettingsDialog({
    super.key,
    required this.listConfig,
    required this.allConfigs,
    required this.onSave,
    this.onDelete,
    this.isDeletable = false,
  });

  @override
  State<ListSettingsDialog> createState() => _ListSettingsDialogState();
}

class _ListSettingsDialogState extends State<ListSettingsDialog> {
  late String _selectedIconName;
  late String _swipeLeftTargetUuid;
  late String _swipeRightTargetUuid;
  late int _selectedColorValue;
  late List<CardIconEntry> _selectedCardIcons;

  @override
  void initState() {
    super.initState();
    _selectedIconName = widget.listConfig.iconName;
    // Ensure swipe values are valid dropdown entries (must be a sibling list UUID or empty)
    final siblingIds = widget.allConfigs
        .where((c) => c.uuid != widget.listConfig.uuid)
        .map((c) => c.uuid)
        .toSet();
    final rawLeft = widget.listConfig.swipeActions['left'] ?? '';
    final rawRight = widget.listConfig.swipeActions['right'] ?? '';
    _swipeLeftTargetUuid = siblingIds.contains(rawLeft) ? rawLeft : '';
    _swipeRightTargetUuid = siblingIds.contains(rawRight) ? rawRight : '';
    _selectedColorValue = widget.listConfig.colorValue;
    _selectedCardIcons = List.from(widget.listConfig.cardIcons);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Settings for ${widget.listConfig.name}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('List Icon:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: iconMapForLists.entries.map((entry) {
                return ChoiceChip(
                  label: Icon(entry.value),
                  selected: _selectedIconName == entry.key,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedIconName = entry.key;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('List Color:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: availableColors.map((color) {
                return ChoiceChip(
                  label: Container(
                    width: 24,
                    height: 24,
                    color: color,
                  ),
                  selected: _selectedColorValue == color.toARGB32(),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedColorValue = color.toARGB32();
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Swipe Left Action:'),
            DropdownButton<String>(
              value: _swipeLeftTargetUuid,
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(value: '', child: Text('None')),
                ...widget.allConfigs
                    .where((config) => config.uuid != widget.listConfig.uuid)
                    .map((config) {
                  return DropdownMenuItem<String>(
                    value: config.uuid,
                    child: Text(config.name),
                  );
                }),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _swipeLeftTargetUuid = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Swipe Right Action:'),
            DropdownButton<String>(
              value: _swipeRightTargetUuid,
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(value: '', child: Text('None')),
                ...widget.allConfigs
                    .where((config) => config.uuid != widget.listConfig.uuid)
                    .map((config) {
                  return DropdownMenuItem<String>(
                    value: config.uuid,
                    child: Text(config.name),
                  );
                }),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _swipeRightTargetUuid = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Icons to Show on Card (up to 5):'),
            const SizedBox(height: 8),
            ...widget.allConfigs
                .where((config) => config.uuid != widget.listConfig.uuid)
                .map((targetConfig) {
              final isSelected = _selectedCardIcons.any(
                (e) => e.targetListId == targetConfig.uuid,
              );

              return CheckboxListTile(
                title: Row(
                  children: [
                    Icon(targetConfig.icon),
                    const SizedBox(width: 8),
                    Text('To ${targetConfig.name}'),
                  ],
                ),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      if (_selectedCardIcons.length < 5) {
                        _selectedCardIcons.add(CardIconEntry(
                          iconName: targetConfig.iconName,
                          targetListId: targetConfig.uuid,
                        ));
                      }
                    } else {
                      _selectedCardIcons.removeWhere(
                        (e) => e.targetListId == targetConfig.uuid,
                      );
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
      actions: [
        if (widget.isDeletable && widget.onDelete != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onDelete!();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete List'),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Filter out empty swipe targets
            final swipeActions = <String, String>{};
            if (_swipeLeftTargetUuid.isNotEmpty) {
              swipeActions['left'] = _swipeLeftTargetUuid;
            }
            if (_swipeRightTargetUuid.isNotEmpty) {
              swipeActions['right'] = _swipeRightTargetUuid;
            }
            final updatedConfig = widget.listConfig.copyWith(
              iconName: _selectedIconName,
              colorValue: _selectedColorValue,
              swipeActions: swipeActions,
              cardIcons: _selectedCardIcons,
            );
            widget.onSave(updatedConfig);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
