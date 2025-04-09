// lib/status_card_list.dart
import 'package:flutter/material.dart';

// Item model
class Item {
  final String id;
  final String title;
  final String subtitle;
  final String text;
  String status;

  Item({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.text,
    required this.status,
  });
}

// Reusable StatusCardList widget
class StatusCardList extends StatelessWidget {
  final List<Item> items;
  final Map<String, IconData> statusIcons;
  final Map<String, String> swipeActions;
  final Function(Item, String) onStatusChanged;

  const StatusCardList({
    super.key,
    required this.items,
    required this.statusIcons,
    required this.swipeActions,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => StatusCard(
        key: ValueKey(items[index].id),
        item: items[index],
        statusIcons: statusIcons,
        swipeActions: swipeActions,
        onStatusChanged: onStatusChanged,
      ),
    );
  }
}

// Individual card with swipe functionality
class StatusCard extends StatefulWidget {
  final Item item;
  final Map<String, IconData> statusIcons;
  final Map<String, String> swipeActions;
  final Function(Item, String) onStatusChanged;

  const StatusCard({
    super.key,
    required this.item,
    required this.statusIcons,
    required this.swipeActions,
    required this.onStatusChanged,
  });

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  String? _swipeState;
  late AnimationController _controller;
  late Animation<double> _animation;
  static const double _maxDrag = 100.0;
  static const double _threshold = 60.0;
  static const double _cardHeight = 140.0; // Increased height for better spacing

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller)
      ..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-_maxDrag, _maxDrag);
      if (_dragOffset > 0) {
        _swipeState = 'save';
      } else if (_dragOffset < 0) {
        _swipeState = 'trash';
      } else {
        _swipeState = null;
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() >= _maxDrag) {
      // Swipe is fully completed, trigger the action
      final action = _dragOffset > 0 ? 'save' : 'trash';
      _triggerAction(action);
    } else if (_dragOffset.abs() > _threshold) {
      // Partial swipe beyond threshold, animate to the edge but don't trigger action yet
      final target = _dragOffset > 0 ? _maxDrag : -_maxDrag;
      _animation = Tween<double>(begin: _dragOffset, end: target).animate(_controller);
      _controller.forward(from: 0);
    } else {
      // Swipe didn't reach threshold, animate back to center
      _animateBack();
    }
  }

  void _animateBack() {
    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(_controller);
    _controller.forward(from: 0).then((_) {
      setState(() {
        _dragOffset = 0;
        _swipeState = null;
      });
    });
  }

  void _animateOffScreen(double target) {
    _animation = Tween<double>(begin: _dragOffset, end: target).animate(_controller);
    _controller.forward(from: 0).then((_) {
      setState(() {
        _swipeState = null;
      });
    });
  }

  void _triggerAction(String action) {
    final newStatus = widget.swipeActions[action];
    if (newStatus != null) {
      widget.onStatusChanged(widget.item, newStatus);
      _animateOffScreen(action == 'save' ? MediaQuery.of(context).size.width : -MediaQuery.of(context).size.width);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardHeight, // Still 140.0
      child: GestureDetector(
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        onTap: () {
          if (_swipeState != null) {
            _animateBack();
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              child: Visibility(
                visible: _swipeState == 'save' || _dragOffset > 0,
                child: Container(
                  width: _maxDrag,
                  height: _cardHeight,
                  color: Colors.blue,
                  child: TextButton(
                    onPressed: () => _triggerAction('save'),
                    child: const Text('SAVE', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Visibility(
                visible: _swipeState == 'trash' || _dragOffset < 0,
                child: Container(
                  width: _maxDrag,
                  height: _cardHeight,
                  color: Colors.red,
                  child: TextButton(
                    onPressed: () => _triggerAction('trash'),
                    child: const Text('TRASH', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Reduced from 12.0 to 8.0
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(widget.item.title, style: const TextStyle(fontSize: 14)), // Smaller font
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2.0), // Reduced from 4.0
                          child: Text(widget.item.subtitle, style: const TextStyle(fontSize: 12)), // Smaller font
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0), // Reduced from 4.0
                        child: Text(widget.item.text, style: const TextStyle(fontSize: 12)), // Smaller font
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: widget.statusIcons.entries.map((entry) {
                          return IconButton(
                            icon: Icon(
                              entry.value,
                              color: widget.item.status == entry.key ? Colors.blue : Colors.grey,
                              size: 20, // Smaller icon size
                            ),
                            onPressed: () => widget.onStatusChanged(widget.item, entry.key),
                            padding: const EdgeInsets.all(4.0), // Reduced padding
                            constraints: const BoxConstraints(), // Remove default constraints
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}