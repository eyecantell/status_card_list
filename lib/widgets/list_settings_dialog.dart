import 'package:flutter/material.dart';
import '../list_config.dart';

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
  late IconData _selectedIcon;
  late String _swipeLeftTargetUuid;
  late String _swipeRightTargetUuid;
  late Color _selectedColor;
  late List<MapEntry<String, String>> _selectedCardIcons;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.listConfig.icon;
    _swipeLeftTargetUuid = widget.listConfig.swipeActions['left'] ?? '';
    _swipeRightTargetUuid = widget.listConfig.swipeActions['right'] ?? '';
    _selectedColor = widget.listConfig.color;
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
                  selected: _selectedIcon == entry.value,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedIcon = entry.value;
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
                  selected: _selectedColor == color,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedColor = color;
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
              final targetConfig = widget.allConfigs.firstWhere((config) => config.uuid == targetUuid);
              final isSelected = _selectedCardIcons.any((e) => e.key == iconName && e.value == targetUuid);

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
                        _selectedCardIcons.add(MapEntry(iconName, targetUuid));
                      }
                    } else {
                      _selectedCardIcons.removeWhere((e) => e.key == iconName && e.value == targetUuid);
                    }
                  });
                },
              );
            }).toList(),
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
            widget.listConfig.icon = _selectedIcon;
            widget.listConfig.color = _selectedColor;
            widget.listConfig.swipeActions['left'] = _swipeLeftTargetUuid;
            widget.listConfig.swipeActions['right'] = _swipeRightTargetUuid;
            widget.listConfig.cardIcons = _selectedCardIcons;
            widget.onSave(widget.listConfig);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}