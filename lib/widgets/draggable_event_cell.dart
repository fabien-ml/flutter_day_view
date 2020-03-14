import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';

class DraggableEventCell extends StatefulWidget {
  final Event event;
  final bool isShortEvent;
  final double fontSize;
  final double width;
  final double height;
  final double heightWhenDragging;
  final Color textColor;
  final Color backgroundColor;
  final Color textColorInverted;
  final Color backgroundColorInverted;
  final Color separatorColor;
  final VoidCallback dragStartHandler;
  final VoidCallback dragEndHandler;
  final Function(double) onUpdatePointerYPosition;

  DraggableEventCell({
    @required this.event,
    @required this.isShortEvent,
    @required this.fontSize,
    @required this.width,
    @required this.height,
    @required this.heightWhenDragging,
    @required this.textColor,
    @required this.backgroundColor,
    @required this.textColorInverted,
    @required this.backgroundColorInverted,
    @required this.separatorColor,
    @required this.dragStartHandler,
    @required this.dragEndHandler,
    @required this.onUpdatePointerYPosition,
  });

  @override
  _DraggableEventCellState createState() => _DraggableEventCellState();
}

class _DraggableEventCellState extends State<DraggableEventCell> {
  double _pointerYPosition;

  EventCellContent _buildCellContent(Color textColor, Color backgroundColor) {
    return EventCellContent(
      event: widget.event,
      isShortEvent: widget.isShortEvent,
      fontSize: widget.fontSize,
      height: widget.height,
      width: widget.width,
      textColor: textColor,
      backgroundColor: backgroundColor,
      separatorColor: widget.separatorColor,
    );
  }

  @override
  void initState() {
    super.initState();
    _pointerYPosition = 0;
  }

  void _updatePointerYPosition(double newOffset) {
    setState(() {
      _pointerYPosition = newOffset;
      widget.onUpdatePointerYPosition(_pointerYPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildCellContent(
      widget.textColor,
      widget.backgroundColor,
    );

    final contentWithColorInverted = _buildCellContent(
      widget.textColorInverted,
      widget.backgroundColorInverted,
    );

    return Listener(
      child: GestureDetector(
        onTapDown: (details) => _updatePointerYPosition(details.localPosition.dy),
        child: LongPressDraggable<Event>(
          data: widget.event,
          hapticFeedbackOnStart: true,
          onDragStarted: () => widget.dragStartHandler(),
          onDragEnd: (_) => widget.dragEndHandler(),
          maxSimultaneousDrags: 1,
          childWhenDragging: Container(
            height: widget.height,
            width: widget.width,
            color: Colors.transparent,
          ),
          feedbackOffset: Offset(0, -(_pointerYPosition)),
          feedback: Container(
            height: widget.heightWhenDragging,
            width: widget.width,
            decoration: BoxDecoration(
              boxShadow: [
                new BoxShadow(
                  color:
                  contentWithColorInverted.backgroundColor.withOpacity(0.5),
                  offset: new Offset(0, 5),
                  blurRadius: 10,
                )
              ],
            ),
            child: contentWithColorInverted,
          ),
          child: content,
        ),
      ),
    );
  }
}

class EventCellContent extends StatelessWidget {
  final Event event;
  final bool isShortEvent;
  final double fontSize;
  final double width;
  final double height;
  final Color textColor;
  final Color backgroundColor;
  final Color separatorColor;

  const EventCellContent({
    @required this.event,
    @required this.isShortEvent,
    @required this.fontSize,
    @required this.width,
    @required this.height,
    @required this.textColor,
    @required this.backgroundColor,
    @required this.separatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 1,
            color: separatorColor,
          ),
          Expanded(
            child: Padding(
              padding: isShortEvent
                  ? EdgeInsets.symmetric(vertical: 2, horizontal: 4)
                  : EdgeInsets.all(4),
              child: Text(
                "${event.title} (${DateFormat.Hm().format(event.startDate)}-${DateFormat.Hm().format(event.endDate)})",
                maxLines: isShortEvent ? 1 : 3,
                overflow: TextOverflow.ellipsis,
                //softWrap: true,
                style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.normal,
                    decoration: TextDecoration.none),
              ),
            ),
          )
        ],
      ),
    );
  }
}