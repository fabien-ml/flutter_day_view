import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayView extends StatefulWidget {
  static const int HOURS_PER_DAY = 24;
  static const int MINUTES_PER_DAY = 1440;

  static const double DEFAULT_HOUR_ROW_HEIGHT = 60;
  static const double DEFAULT_MIN_EVENT_HEIGHT = DEFAULT_HOUR_ROW_HEIGHT / 4;
  static const double DEFAULT_EVENT_ROW_LEFT_OFFSET = 60;
  static const double BASE_TOP_OFFSET = 8;
  static const double SCROLL_STEP_BASIS = DayView.DEFAULT_HOUR_ROW_HEIGHT * 2;

  double hourRowHeight;

  DayView({
    this.hourRowHeight = DEFAULT_HOUR_ROW_HEIGHT,
  });

  @override
  _DayViewState createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  ScrollController _scrollController;
  bool _dragEventStarted = false;

  double get height {
    return this.widget.hourRowHeight * DayView.HOURS_PER_DAY;
  }

  double get sizeOfOneMinute {
    return (1 * this.height) / DayView.MINUTES_PER_DAY;
  }

  @override
  void initState() {
    super.initState();
    final initialScrollOffset =
        _getTopPositionFromDateTime(DateTime.now()) - 300;
    _scrollController =
        ScrollController(initialScrollOffset: initialScrollOffset);
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void _onDragEventStart() {
    setState(() {
      _dragEventStarted = true;
    });
  }

  void _onDragEventEnd() {
    setState(() {
      _dragEventStarted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final mediaQuery = MediaQuery.of(context);
    final availableEventWidth = mediaQuery.size.width - DayView.DEFAULT_EVENT_ROW_LEFT_OFFSET;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Stack(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: this.height + DayView.DEFAULT_HOUR_ROW_HEIGHT,
                  child: Column(
                    children: _buildHourRows(today),
                  ),
                ),
                ..._buildPositionedEvents(availableEventWidth),
                Positioned(
                  top: _getTopPositionFromDateTime(today),
                  left: 20,
                  right: 0,
                  child: TodayLineIndicator(
                    date: today,
                  ),
                ),
                Positioned(
                  top: DayView.BASE_TOP_OFFSET,
                  left: 16,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    child: Column(
                      children: List<Widget>.generate(96, (index) {
                        return Container(
                          width: mediaQuery.size.width,
                          height: DayView.DEFAULT_MIN_EVENT_HEIGHT,
                          child: DragTarget<Event>(
                            builder: (context, candidates, rejects) {
                              final hourLabel = _getHourFromTopOffset(
                                  index * DayView.DEFAULT_MIN_EVENT_HEIGHT +
                                      8);

                              return candidates.length > 0
                                  ? Container(
                                      child: Text(
                                        hourLabel,
                                        style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    )
                                  : null;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getHourFromTopOffset(double offset) {
    double totalMinutes = ((offset * DayView.MINUTES_PER_DAY) / height);
    int hour = (totalMinutes / 60).truncate();
    int minutes = ((totalMinutes % 60) - ((totalMinutes % 60) % 15)).truncate();
    final now = DateTime.now();
    final dateFromTopOffset =
        DateTime(now.year, now.month, now.day, hour, minutes, 0);
    return DateFormat.Hm().format(dateFromTopOffset);
  }

  List<Widget> _buildHourRows(DateTime now) {
    List<Widget> hourRows = [];

    DateTime todayAtStartOfDay =
        DateTime(now.year, now.month, now.day, 0, 0, 0);

    for (var i = 0; i < DayView.HOURS_PER_DAY; i++) {
      DateTime todayAtStartOfDayPlusXHours =
          todayAtStartOfDay.add(Duration(hours: i));

      hourRows.add(Container(
        height: this.widget.hourRowHeight,
        child: HourLineSeparator(
          hourLabel: DateFormat.Hm().format(todayAtStartOfDayPlusXHours),
          showHourLabel: _shouldShowRowHour(now, todayAtStartOfDayPlusXHours),
        ),
      ));
    }

    DateTime tomorrowAtStartOfDay = todayAtStartOfDay.add(Duration(days: 1));

    hourRows.add(HourLineSeparator(
      hourLabel: DateFormat.Hm().format(tomorrowAtStartOfDay),
      showHourLabel: _shouldShowRowHour(now, tomorrowAtStartOfDay),
    ));

    return hourRows;
  }

  bool _shouldShowRowHour(DateTime date1, DateTime date2) {
    double safeAreaHeight = 14 / sizeOfOneMinute;

    int difference = date1.difference(date2).inMinutes.abs();
    return difference > safeAreaHeight;
  }

  DateTime todayAt(int hour, int min) {
    var today = DateTime.now();
    return DateTime(today.year, today.month, today.day, hour, min, 0);
  }

  List<Positioned> _buildPositionedEvents(double rowWidth) {
    List<Positioned> positionedEvents = [];

    var now = DateTime.now();

    List<Event> events = [
      Event("0", todayAt(0, 0), todayAt(1, 0), false, "First"),
      Event("1", todayAt(8, 0), todayAt(18, 0), false, "AG"),
      Event("2", todayAt(8, 0), todayAt(12, 0), false, "NPD"),
      Event("3", todayAt(9, 30), todayAt(11, 30), false, "veille"),
      Event("4", todayAt(12, 00), todayAt(13, 30), false, "Ref"),
      Event("5", todayAt(15, 30), todayAt(17, 0), false, "Bklg"),
      Event("6", todayAt(17, 0), todayAt(18, 0), false, "2020"),
    ];

    SplayTreeMap<int, List<Event>> groupedEvents =
        SplayTreeMap((a, b) => a.compareTo(b));

    events.forEach((event) {
      final key = _getKeyForEvent(event);

      if (groupedEvents.containsKey(key)) {
        groupedEvents[key].add(event);
      } else {
        groupedEvents[key] = [event];
      }
    });

    groupedEvents.values.forEach((eventList) {
      final eventWidth = rowWidth / eventList.length;
      int index = 0;

      eventList.sort((a, b) => a.startDate.compareTo(b.startDate));

      eventList.forEach((event) {
        final int indent = groupedEvents.values
            .expand((it) => it.toList())
            .where((it) =>
                it.startDate.isBefore(event.startDate) &&
                it.endDate.isAfter(event.startDate))
            .where((it) => _getKeyForEvent(it) != _getKeyForEvent(event))
            .length;

        final topOffset = DayView.BASE_TOP_OFFSET +
            1 +
            _getTopPositionFromDateTime(event.startDate);

        final baseEventHeight =
            _getEventHeightFromDuration(event.durationInMinutes) - 2;

        final eventHeight = baseEventHeight < DayView.DEFAULT_MIN_EVENT_HEIGHT
            ? DayView.DEFAULT_MIN_EVENT_HEIGHT
            : baseEventHeight;

        final isShortEvent = eventHeight <= DayView.DEFAULT_MIN_EVENT_HEIGHT;

        double fontSize = 12;

        if (isShortEvent && (eventHeight / 2) < 6) {
          fontSize = 6;
        } else if (isShortEvent) {
          fontSize = (eventHeight / 2);
        }

        final eventCell = DraggableEventCell(
          indent: indent,
          event: event,
          isShortEvent: isShortEvent,
          fontSize: fontSize,
          width: eventWidth,
          height: eventHeight,
          textColor: Colors.blue[800],
          backgroundColor: Colors.blue[100].withOpacity(0.7),
          textColorInverted: Colors.white,
          backgroundColorInverted: Colors.blue[500],
          separatorColor: Colors.blue[500],
          dragStartHandler: _onDragEventStart,
          dragEndHandler: _onDragEventEnd,
        );

        positionedEvents.add(
          Positioned(
            left: DayView.DEFAULT_EVENT_ROW_LEFT_OFFSET +
                (eventWidth * index) +
                (indent * 5),
            top: topOffset,
            height: eventHeight,
            width: eventWidth,
            child: eventCell,
          ),
        );
        index++;
      });
    });

    return positionedEvents;
  }

  int _getKeyForEvent(Event event) {
    // key is start time floored to nearest quarter hour in minutes
    // ex: 01:27 -> 01:15 -> 75
    return event.startDate.floorToNearestQuarterHour().roundToMinutes();
  }

  double _getTopPositionFromDateTime(DateTime date) {
    double minutes = date.minute + (date.hour * 60.0);
    return (minutes * this.height) / DayView.MINUTES_PER_DAY;
  }

  double _getEventHeightFromDuration(int durationInMinutes) {
    return (sizeOfOneMinute * durationInMinutes);
  }
}

class DraggableEventCell extends StatefulWidget {
  final int indent;
  final Event event;
  final bool isShortEvent;
  final double fontSize;
  final double width;
  final double height;
  final Color textColor;
  final Color backgroundColor;
  final Color textColorInverted;
  final Color backgroundColorInverted;
  final Color separatorColor;
  final VoidCallback dragStartHandler;
  final VoidCallback dragEndHandler;

  DraggableEventCell({
    @required this.event,
    @required this.isShortEvent,
    @required this.fontSize,
    @required this.width,
    @required this.height,
    @required this.textColor,
    @required this.backgroundColor,
    @required this.textColorInverted,
    @required this.backgroundColorInverted,
    @required this.separatorColor,
    @required this.indent,
    @required this.dragStartHandler,
    @required this.dragEndHandler,
  });

  @override
  _DraggableEventCellState createState() => _DraggableEventCellState();
}

class _DraggableEventCellState extends State<DraggableEventCell> {
  double _localYOffset;

  EventCellContent _buildCellContent(Color textColor, Color backgroundColor) {
    return EventCellContent(
      indent: widget.indent,
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
    _localYOffset = 0;
  }

  void _updateLocalYOffset(double newOffset) {
    setState(() {
      _localYOffset = newOffset;
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

    return GestureDetector(
      onTapDown: (details) => _updateLocalYOffset(-details.localPosition.dy),
      child: LongPressDraggable<Event>(
        data: widget.event,
        hapticFeedbackOnStart: true,
        onDragStarted: () => widget.dragStartHandler(),
        onDragEnd: (_) => widget.dragEndHandler(),
        maxSimultaneousDrags: 1,
        childWhenDragging: Container(
          height: widget.height,
          width: widget.width,
          color: Colors.orange[100],
        ),
        feedbackOffset: Offset(0, _localYOffset),
        feedback: Container(
          height: widget.height,
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
    );
  }
}

class EventCellContent extends StatelessWidget {
  final int indent;
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
    @required this.indent,
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
                event.title + "($indent)",
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

extension DateTimeExtension on DateTime {
  DateTime floorToNearestQuarterHour() {
    return this.subtract(Duration(minutes: (this.minute % 15)));
  }

  int roundToMinutes() {
    return (this.hour * 60) + this.minute;
  }
}

class Event {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final bool allDay;
  final String title;

  const Event(this.id, this.startDate, this.endDate, this.allDay, this.title);

  int get durationInMinutes {
    return startDate.difference(endDate).inMinutes.abs();
  }
}

class HourLineSeparator extends StatelessWidget {
  final String hourLabel;
  final bool showHourLabel;

  HourLineSeparator({
    @required this.hourLabel,
    @required this.showHourLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showHourLabel)
            Text(
              hourLabel,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: showHourLabel ? 4 : 42),
              child: Divider(
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayLineIndicator extends StatelessWidget {
  final DateTime date;
  final Color color;
  final Color circleBorderColor;

  TodayLineIndicator({
    @required this.date,
    this.color = Colors.red,
    this.circleBorderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            DateFormat.Hm().format(this.date),
            style: TextStyle(
              color: this.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: LineIndicator(
                color: this.color,
                circleBorderColor: this.circleBorderColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LineIndicator extends StatelessWidget {
  final Color color;
  final Color circleBorderColor;

  LineIndicator({@required this.color, @required this.circleBorderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Stack(
        children: <Widget>[
          Positioned(
            height: 1,
            top: 5,
            left: 0,
            right: 0,
            child: Divider(
              color: this.color,
              thickness: 1,
            ),
          ),
          Container(
            height: 11,
            width: 11,
            margin: EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              border: Border.all(color: this.circleBorderColor, width: 1),
              color: this.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
