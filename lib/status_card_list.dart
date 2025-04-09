import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

// Item model
class Item {
  final String id;
  final String title;
  final String subtitle;
  final String html;
  String status;

  Item({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.html,
    required this.status,
  });
}

// Reusable StatusCardList widget (StatefulWidget)
class StatusCardList extends StatefulWidget {
  final List<Item> initialItems;
  final Map<String, IconData> statusIcons;
  final Map<String, String> swipeActions;
  final Function(Item, String) onStatusChanged;

  const StatusCardList({
    super.key,
    required this.initialItems,
    required this.statusIcons,
    required this.swipeActions,
    required this.onStatusChanged,
  });

  @override
  State<StatusCardList> createState() => _StatusCardListState();
}

class _StatusCardListState extends State<StatusCardList> {
  late List<Item> items;

  @override
  void initState() {
    super.initState();
    items = List.from(widget.initialItems);
  }

  void _handleStatusChanged(Item item, String newStatus) {
    item.status = newStatus;
    widget.onStatusChanged(item, newStatus);
    setState(() {
      items.removeWhere((i) => i.id == item.id);
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final Item item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: _onReorder,
      children: [
        for (int index = 0; index < items.length; index++)
          StatusCard(
            key: ValueKey(items[index].id),
            item: items[index],
            index: index,
            statusIcons: widget.statusIcons,
            swipeActions: widget.swipeActions,
            onStatusChanged: _handleStatusChanged,
          ),
      ],
    );
  }
}

// Individual card with swipe functionality
class StatusCard extends StatefulWidget {
  final Item item;
  final int index;
  final Map<String, IconData> statusIcons;
  final Map<String, String> swipeActions;
  final Function(Item, String) onStatusChanged;

  const StatusCard({
    super.key,
    required this.item,
    required this.index,
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
  static const double _defaultCardHeight = 165.0;
  bool _isExpanded = false;
  bool _isActionTriggered = false;
  final GlobalKey _cardKey = GlobalKey();
  double? _cardHeight;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCardHeight();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateCardHeight() {
    final RenderBox? renderBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      setState(() {
        _cardHeight = renderBox.size.height;
      });
    }
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
      _animation = Tween<double>(begin: _dragOffset, end: target).animate(_controller)
        ..addListener(() {
          setState(() {
            _dragOffset = _animation.value;
          });
        });
      _controller.forward(from: 0);
    } else {
      _animateBack();
    }
  }

  void _animateBack() {
    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(_controller)
      ..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });
    _controller.forward(from: 0).then((_) {
      setState(() {
        _dragOffset = 0;
        _swipeState = null;
        _isActionTriggered = false;
      });
    });
  }

  Future<void> _animateOffScreen(double target) async {
    _animation = Tween<double>(begin: _dragOffset, end: target).animate(_controller)
      ..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });
    await _controller.forward(from: 0); // Wait for the animation to complete
    setState(() {
      _dragOffset = 0;
      _isActionTriggered = false;
    });
  }

  void _triggerAction(String action) {
    final newStatus = widget.swipeActions[action];
    if (newStatus != null) {
      setState(() {
        _swipeState = null;
        _isActionTriggered = true;
      });
      _animateOffScreen(action == 'save' ? MediaQuery.of(context).size.width : -MediaQuery.of(context).size.width)
          .then((_) {
        widget.onStatusChanged(widget.item, newStatus);
      });
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateCardHeight();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 0,
          child: Visibility(
            visible: !_isActionTriggered && (_swipeState == 'save' || _dragOffset > 0),
            child: Container(
              width: _buttonWidth,
              height: _cardHeight ?? _defaultCardHeight,
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
            visible: !_isActionTriggered && (_swipeState == 'trash' || _dragOffset < 0),
            child: Container(
              width: _buttonWidth,
              height: _cardHeight ?? _defaultCardHeight,
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
        GestureDetector(
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          onTap: () {
            if (_dragOffset == 0) {
              _toggleExpanded();
            } else {
              _animateBack();
            }
          },
          child: Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: SizedBox(
              child: Card(
                key: _cardKey,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
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
                            if (_isExpanded)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Html(
                                  data: widget.item.html,
                                  style: {
                                    'h2': Style(
                                      fontSize: FontSize(18.0),
                                      fontWeight: FontWeight.bold,
                                      margin: Margins.all(8.0),
                                    ),
                                    'p': Style(
                                      fontSize: FontSize(14.0),
                                      margin: Margins.all(8.0),
                                    ),
                                    'table': Style(
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    'th': Style(
                                      backgroundColor: Colors.grey[200],
                                      padding: HtmlPaddings.all(8.0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    'td': Style(
                                      padding: HtmlPaddings.all(8.0),
                                    ),
                                  },
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: widget.statusIcons.entries.map((entry) {
                                return [
                                  IconButton(
                                    icon: Icon(
                                      entry.value,
                                      color: widget.item.status == entry.key ? Colors.blue : Colors.grey,
                                    ),
                                    onPressed: () {
                                      final action = entry.key == 'done' ? 'save' : 'trash';
                                      _triggerAction(action);
                                    },
                                  ),
                                  if (entry.key != widget.statusIcons.keys.last)
                                    const SizedBox(width: 16), // Corrected here
                                ];
                              }).expand((element) => element).toList(),
                            ),
                          ],
                        ),
                      ),
                      ReorderableDragStartListener(
                        index: widget.index,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}