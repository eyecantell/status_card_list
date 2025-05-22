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
  late String _swipeLeftTarget;
  late String _swipeRightTarget;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.listConfig.icon;
    _swipeLeftTarget = widget.listConfig.swipeActions['left'] ?? '';
    _swipeRightTarget = widget.listConfig.swipeActions['right'] ?? '';
    _selectedColor = widget.listConfig.color;
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
              value: _swipeLeftTarget,
              isExpanded: true,
              items: widget.allConfigs.map((config) {
                return DropdownMenuItem<String>(
                  value: config.name,
                  child: Text(config.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _swipeLeftTarget = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Swipe Right Action:'),
            DropdownButton<String>(
              value: _swipeRightTarget,
              isExpanded: true,
              items: widget.allConfigs.map((config) {
                return DropdownMenuItem<String>(
                  value: config.name,
                  child: Text(config.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _swipeRightTarget = value;
                  });
                }
              },
            ),
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
            widget.listConfig.swipeActions['left'] = _swipeLeftTarget;
            widget.listConfig.swipeActions['right'] = _swipeRightTarget;
            widget.onSave(widget.listConfig);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}