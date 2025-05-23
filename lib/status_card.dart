import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'item.dart';
import 'list_config.dart';
import '../data.dart'; // Import Data to access itemMap

class StatusCard extends StatefulWidget {
  final Item item;
  final int index;
  final Map<String, IconData> statusIcons;
  final Map<String, String> swipeActions;
  final Function(Item, String) onStatusChanged;
  final Function(int, int) onReorder;
  final String dueDateLabel;
  final Color listColor;
  final List<ListConfig> allConfigs;
  final List<MapEntry<String, String>> cardIcons;
  final Map<String, Item> itemMap;
  final Map<String, List<String>> itemLists;
  final Function(String, String) onNavigateToItem;
  final bool isExpanded;
  final bool isNavigated;

  const StatusCard({
    super.key,
    required this.item,
    required this.index,
    required this.statusIcons,
    required this.swipeActions,
    required this.onStatusChanged,
    required this.onReorder,
    required this.dueDateLabel,
    required this.listColor,
    required this.allConfigs,
    required this.cardIcons,
    required this.itemMap,
    required this.itemLists,
    required this.onNavigateToItem,
    this.isExpanded = false,
    this.isNavigated = false,
  });

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> with TickerProviderStateMixin {
  double _dragOffset = 0.0;
  String? _swipeState;
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;
  static const double _maxDrag = 150.0;
  static const double _buttonWidth = 100.0;
  static const double _threshold = 90.0;
  static const double _defaultCardHeight = 165.0;
  late bool _isExpanded;
  bool _isActionTriggered = false;
  final GlobalKey _cardKey = GlobalKey();
  double? _cardHeight;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
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

    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _highlightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _highlightController,
        curve: Curves.easeOut,
      ),
    )..addListener(() {
        setState(() {});
      });

    if (widget.isNavigated && widget.isExpanded) {
      _highlightController.forward();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCardHeight();
    });
  }

  @override
  void didUpdateWidget(StatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      setState(() {
        _isExpanded = widget.isExpanded;
      });
    }
    if (widget.isNavigated && !oldWidget.isNavigated && widget.isExpanded) {
      _highlightController.reset();
      _highlightController.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _highlightController.dispose();
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

  void _handleHorizontalDragStart(DragStartDetails details) {
    print('Horizontal drag started on card: ${widget.item.title}');
    setState(() {
      _dragOffset = 0.0;
      _swipeState = null;
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    print('Horizontal drag update: dx=${details.delta.dx}, dy=${details.delta.dy}');
    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-_maxDrag, _maxDrag);
      if (_dragOffset > 0) {
        _swipeState = 'right';
      } else if (_dragOffset < 0) {
        _swipeState = 'left';
      } else {
        _swipeState = null;
      }
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    print('Horizontal drag ended');
    if (_dragOffset.abs() >= _maxDrag) {
      final action = _dragOffset > 0 ? 'right' : 'left';
      _triggerAction(action: action);
    } else if (_dragOffset.abs() > _threshold) {
      final target = _dragOffset > 0 ? _buttonWidth : -_buttonWidth;
      _animation = Tween<double>(begin: _dragOffset, end: target)
          .animate(_controller)
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
    _animation = Tween<double>(begin: _dragOffset, end: target)
        .animate(_controller)
      ..addListener(() {
        setState(() {
          _dragOffset = _animation.value;
        });
      });
    await _controller.forward(from: 0);
    setState(() {
      _dragOffset = 0;
      _isActionTriggered = false;
    });
  }

  void _triggerAction({String? action, String? targetListUuid}) {
    targetListUuid = targetListUuid ?? (action != null ? widget.swipeActions[action] : null);
    if (targetListUuid != null) {
      setState(() {
        _swipeState = null;
        _isActionTriggered = true;
      });
      final animationDirection = action == 'right'
          ? MediaQuery.of(context).size.width
          : action == 'left'
              ? -MediaQuery.of(context).size.width
              : MediaQuery.of(context).size.width;
      _animateOffScreen(animationDirection).then((_) {
        widget.onStatusChanged(widget.item, targetListUuid!);
      });
    }
  }

  void _toggleExpanded() {
    print('Card tapped: ${widget.item.title}');
    setState(() {
      _isExpanded = !_isExpanded;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateCardHeight();
      });
    });
  }

  Color _getTargetColor(String action) {
    final targetListUuid = widget.swipeActions[action];
    if (targetListUuid != null) {
      final targetConfig = widget.allConfigs.firstWhere(
        (config) => config.uuid == targetListUuid,
        orElse: () => widget.allConfigs[0],
      );
      return targetConfig.color;
    }
    return widget.listColor;
  }

  IconData _getTargetIcon(String action) {
    final targetListUuid = widget.swipeActions[action];
    if (targetListUuid != null) {
      final targetConfig = widget.allConfigs.firstWhere(
        (config) => config.uuid == targetListUuid,
        orElse: () => widget.allConfigs[0],
      );
      return targetConfig.icon;
    }
    return widget.allConfigs[0].icon;
  }

  String _getTargetName(String action) {
    final targetListUuid = widget.swipeActions[action];
    if (targetListUuid != null) {
      final targetConfig = widget.allConfigs.firstWhere(
        (config) => config.uuid == targetListUuid,
        orElse: () => widget.allConfigs[0],
      );
      return targetConfig.name;
    }
    return 'ACTION';
  }

  String _formatDueDateAndDays(DateTime dueDate) {
    final today = DateTime(2025, 5, 22);
    final difference = dueDate.difference(today).inDays;
    String daysText;

    if (difference == 0) {
      daysText = 'today';
    } else if (difference == 1) {
      daysText = 'tomorrow';
    } else if (difference == -1) {
      daysText = 'yesterday';
    } else if (difference > 0) {
      daysText = 'in $difference days';
    } else {
      daysText = '${-difference} days ago';
    }

    final formattedDate = '${dueDate.month}/${dueDate.day}/${dueDate.year}';
    return '${widget.dueDateLabel}: $formattedDate ($daysText)';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final rightListName = _getTargetName('right');
    final leftListName = _getTargetName('left');

    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 0,
          child: Visibility(
            visible: !_isActionTriggered && (_swipeState == 'right' || _dragOffset > 0),
            child: Container(
              width: _buttonWidth,
              height: _cardHeight ?? _defaultCardHeight,
              color: _getTargetColor('right'),
              child: TextButton(
                onPressed: () {
                  final targetUuid = widget.swipeActions['right'];
                  if (targetUuid != null) _triggerAction(action: 'right');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rightListName.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      _getTargetIcon('right'),
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
            visible: !_isActionTriggered && (_swipeState == 'left' || _dragOffset < 0),
            child: Container(
              width: _buttonWidth,
              height: _cardHeight ?? _defaultCardHeight,
              color: _getTargetColor('left'),
              child: TextButton(
                onPressed: () {
                  final targetUuid = widget.swipeActions['left'];
                  if (targetUuid != null) _triggerAction(action: 'left');
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      leftListName.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      _getTargetIcon('left'),
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
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border: widget.isNavigated && _highlightAnimation.value > 0
                  ? Border.all(
                      color: Colors.blue.withOpacity(_highlightAnimation.value),
                      width: 2.0,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleExpanded,
              onHorizontalDragStart: _handleHorizontalDragStart,
              onHorizontalDragUpdate: _handleHorizontalDragUpdate,
              onHorizontalDragEnd: _handleHorizontalDragEnd,
              child: Card(
                key: _cardKey,
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(
                                widget.item.title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Status: ${widget.item.status}${widget.item.relatedItemIds.isNotEmpty ? ", ${widget.item.relatedItemIds.length} related item${widget.item.relatedItemIds.length == 1 ? '' : 's'}" : ''}',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      _formatDueDateAndDays(widget.item.dueDate),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                            if (_isExpanded) ...[
                              if (widget.item.relatedItemIds.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Related Items:',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode ? Colors.white : Colors.black,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: widget.item.relatedItemIds.length,
                                        itemBuilder: (context, index) {
                                          final relatedId = widget.item.relatedItemIds[index];
                                          final relatedItem = widget.itemMap[relatedId];
                                          final targetListUuid = widget.itemLists.entries
                                              .firstWhere(
                                                (entry) => entry.value.contains(relatedId),
                                                orElse: () => MapEntry('', <String>[]),
                                              )
                                              .key;
                                          final targetConfig = widget.allConfigs.firstWhere(
                                            (config) => config.uuid == targetListUuid,
                                            orElse: () => ListConfig(
                                              name: 'Unknown List',
                                              swipeActions: {},
                                              buttons: {},
                                              dueDateLabel: 'Due Date',
                                              sortMode: SortMode.dateAscending,
                                              icon: Icons.list,
                                              color: Colors.grey,
                                            ),
                                          );
                                          return TextButton(
                                            onPressed: targetListUuid.isNotEmpty
                                                ? () {
                                                    widget.onNavigateToItem(targetListUuid, relatedId);
                                                  }
                                                : null,
                                            child: Text(
                                              '${index + 1}. ${relatedItem?.title ?? 'Unknown Item'} (${targetConfig.name})',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 8.0,
                                ),
                                child: Html(
                                  data: widget.item.html,
                                  style: {
                                    'h2': Style(
                                      fontSize: FontSize(18.0),
                                      fontWeight: FontWeight.bold,
                                      margin: Margins.all(8.0),
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                    'p': Style(
                                      fontSize: FontSize(14.0),
                                      margin: Margins.all(8.0),
                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                    ),
                                    'table': Style(
                                      border: Border.all(
                                        color: isDarkMode ? Colors.grey[600]! : Colors.grey,
                                      ),
                                    ),
                                    'th': Style(
                                      backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                      padding: HtmlPaddings.all(8.0),
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    ),
                                    'td': Style(
                                      padding: HtmlPaddings.all(8.0),
                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                    ),
                                  },
                                ),
                              ),
                            ],
                            if (widget.cardIcons.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: widget.cardIcons.map((entry) {
                                  final targetListUuid = entry.value;
                                  final targetConfig = widget.allConfigs.firstWhere(
                                    (config) => config.uuid == targetListUuid,
                                    orElse: () => widget.allConfigs[0],
                                  );
                                  final icon = targetConfig.icon;
                                  final color = targetConfig.color;

                                  return IconButton(
                                    icon: Icon(icon),
                                    color: color,
                                    iconSize: 48.0,
                                    onPressed: () => _triggerAction(targetListUuid: targetListUuid),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.drag_handle,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          size: 24.0,
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