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
  static const double _maxDrag = 150.0;
  static const double _buttonWidth = 100.0;
  static const double _threshold = 90.0;
  static const double _cardHeight = 165.0;

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
      final action = _dragOffset > 0 ? 'save' : 'trash';
      _triggerAction(action);
    } else if (_dragOffset.abs() > _threshold) {
      final target = _dragOffset > 0 ? _buttonWidth : -_buttonWidth;
      _animation = Tween<double>(begin: _dragOffset, end: target).animate(_controller);
      _controller.forward(from: 0);
    } else {
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
    _controller.forward(from: 0);
  }

  void _triggerAction(String action) {
    final newStatus = widget.swipeActions[action];
    if (newStatus != null) {
      widget.onStatusChanged(widget.item, newStatus);
      setState(() {
        _swipeState = null; // Reset _swipeState immediately to hide buttons
      });
      _animateOffScreen(action == 'save' ? MediaQuery.of(context).size.width : -MediaQuery.of(context).size.width);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardHeight,
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
                visible: _swipeState == 'save', // Simplified condition
                child: Container(
                  width: _buttonWidth,
                  height: _cardHeight,
                  color: Colors.blue,
                  child: TextButton(
                    onPressed: () => _triggerAction('save'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'SAVE',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 36,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: Visibility(
                visible: _swipeState == 'trash', // Simplified condition
                child: Container(
                  width: _buttonWidth,
                  height: _cardHeight,
                  color: Colors.red,
                  child: TextButton(
                    onPressed: () => _triggerAction('trash'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'TRASH',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 36,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(widget.item.title),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(widget.item.subtitle),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Text(widget.item.text),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: widget.statusIcons.entries.map((entry) {
                          return IconButton(
                            icon: Icon(
                              entry.value,
                              color: widget.item.status == entry.key ? Colors.blue : Colors.grey,
                            ),
                            onPressed: () => widget.onStatusChanged(widget.item, entry.key),
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