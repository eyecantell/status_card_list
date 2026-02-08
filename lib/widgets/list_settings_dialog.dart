import 'package:flutter/material.dart';
import '../models/list_config.dart';
import '../utils/constants.dart';

class ListSettingsDialog extends StatefulWidget {
  final ListConfig listConfig;
  final List<ListConfig> allConfigs;
  final Function(ListConfig) onSave;

  const ListSettingsDialog({
    super.key,
    required this.listConfig,
    required this.allConfigs,
    required this.onSave,
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
    _swipeLeftTargetUuid = widget.listConfig.swipeActions['left'] ?? '';
    _swipeRightTargetUuid = widget.listConfig.swipeActions['right'] ?? '';
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
              items: widget.allConfigs
                  .where((config) => config.uuid != widget.listConfig.uuid)
                  .map((config) {
                return DropdownMenuItem<String>(
                  value: config.uuid,
                  child: Text(config.name),
                );
              }).toList(),
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
              items: widget.allConfigs
                  .where((config) => config.uuid != widget.listConfig.uuid)
                  .map((config) {
                return DropdownMenuItem<String>(
                  value: config.uuid,
                  child: Text(config.name),
                );
              }).toList(),
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
            ...widget.listConfig.buttons.entries.map((entry) {
              final iconName = entry.key;
              final targetUuid = entry.value;
              final targetConfig = widget.allConfigs.firstWhere(
                (config) => config.uuid == targetUuid,
                orElse: () => widget.allConfigs.first,
              );
              final isSelected = _selectedCardIcons.any(
                (e) => e.iconName == iconName && e.targetListId == targetUuid,
              );

              return CheckboxListTile(
                title: Row(
                  children: [
                    Icon(iconMap[iconName]),
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
                          iconName: iconName,
                          targetListId: targetUuid,
                        ));
                      }
                    } else {
                      _selectedCardIcons.removeWhere(
                        (e) => e.iconName == iconName && e.targetListId == targetUuid,
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final updatedConfig = widget.listConfig.copyWith(
              iconName: _selectedIconName,
              colorValue: _selectedColorValue,
              swipeActions: {
                'left': _swipeLeftTargetUuid,
                'right': _swipeRightTargetUuid,
              },
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
