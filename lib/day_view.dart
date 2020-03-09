import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayView extends StatefulWidget {
  static const int HOURS_PER_DAY = 24;
  static const int MINUTES_PER_DAY = 1440;
  static const double DEFAULT_HOUR_ROW_HEIGHT = 60;
  static const double DEFAULT_MIN_EVENT_HEIGHT = DEFAULT_HOUR_ROW_HEIGHT / 4;
  static const double DEFAULT_EVENT_ROW_LEFT_OFFSET = 60;
  double hourRowHeight;

  DayView({
    this.hourRowHeight = DEFAULT_HOUR_ROW_HEIGHT,
  });

  @override
  _DayViewState createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  ScrollController _scrollController;

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

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final mediaQuery = MediaQuery.of(context);
    final availableEventWidth =
        mediaQuery.size.width - DayView.DEFAULT_EVENT_ROW_LEFT_OFFSET;
    return SingleChildScrollView(
      controller: _scrollController,
      child: Stack(
        children: <Widget>[
          Container(
            width: double.infinity,
            height: this.height + HourLineSeparator.DEFAULT_HEIGHT,
            child: Column(
              children: _buildHourRows(today),
            ),
          ),
          ...List<Widget>.generate(97, (index) {
            return Positioned(
              top: (index * DayView.DEFAULT_MIN_EVENT_HEIGHT)+ 8,
              left:  DayView.DEFAULT_EVENT_ROW_LEFT_OFFSET,
              width: availableEventWidth,
              height: DayView.DEFAULT_MIN_EVENT_HEIGHT,
              child: Container(
                child: DragTarget<Event>(
                  builder: (context, candidates, rejects) {
                    return candidates.length > 0 ? Container(
                      color: Colors.green,
                    ) : null;
                  },
                ),
              ),
            );
          }).toList(),
          ..._buildPositionedEvents(availableEventWidth),
          Positioned(
            top: _getTopPositionFromDateTime(today),
            left: 20,
            right: 0,
            child: TodayLineIndicator(
              date: today,
            ),
          ),
        ],
      ),
    );
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

  List<Positioned> _buildPositionedEvents(double rowWidth) {
    List<Positioned> positionedEvents = [];

    var now = DateTime.now();

    List<Event> events = [
      Event("1", DateTime(now.year, now.month, now.day, 10, 0, 0),
          DateTime(now.year, now.month, now.day, 10, 15, 0), false, "Event 1"),
      Event("2", DateTime(now.year, now.month, now.day, 14, 45, 0),
          DateTime(now.year, now.month, now.day, 15, 00, 0), false, "Event 2"),
      Event("3", DateTime(now.year, now.month, now.day, 10, 15, 0),
          DateTime(now.year, now.month, now.day, 10, 30, 0), false, "Event 3"),
      Event("4", DateTime(now.year, now.month, now.day, 10, 30, 0),
          DateTime(now.year, now.month, now.day, 10, 45, 0), false, "Event 4"),
      Event(
          "5",
          DateTime(now.year, now.month, now.day, 10, 45, 0),
          DateTime(now.year, now.month, now.day, 11, 0, 0),
          false,
          "Event 5 lorem ipsum dolor sit amet"),
      Event(
          "6",
          DateTime(now.year, now.month, now.day, 8, 0, 0),
          DateTime(now.year, now.month, now.day, 9, 0, 0),
          false,
          "Event 6 Lorem ipsum dolor sit amet"),
      Event("7", DateTime(now.year, now.month, now.day, 14, 0, 0),
          DateTime(now.year, now.month, now.day, 16, 0, 0), false, "Event 7"),
      Event("8", DateTime(now.year, now.month, now.day, 14, 30, 0),
          DateTime(now.year, now.month, now.day, 15, 30, 0), false, "Event 8 "),
      Event("9", DateTime(now.year, now.month, now.day, 8, 37, 0),
          DateTime(now.year, now.month, now.day, 8, 47, 0), false, "Event 9"),
      Event("10", DateTime(now.year, now.month, now.day, 8, 32, 0),
          DateTime(now.year, now.month, now.day, 9, 0, 0), false, "Event 10"),
      Event("11", DateTime(now.year, now.month, now.day, 8, 32, 0),
          DateTime(now.year, now.month, now.day, 9, 0, 0), false, "Event 11"),
      Event("12", DateTime(now.year, now.month, now.day, 14, 45, 0),
          DateTime(now.year, now.month, now.day, 15, 00, 0), false, "Event 12"),
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

        final topOffset = _getTopPositionFromDateTime(event.startDate) +
            (HourLineSeparator.DEFAULT_HEIGHT / 2) +
            1;
        final baseEventHeight =
            _getEventHeightFromDuration(event.durationInMinutes);
        final isShortEvent = baseEventHeight < 25;
        double fontSize = 12;

        final eventHeight = baseEventHeight < DayView.DEFAULT_MIN_EVENT_HEIGHT
            ? DayView.DEFAULT_MIN_EVENT_HEIGHT
            : baseEventHeight;

        if (isShortEvent && (eventHeight / 2) < 6) {
          fontSize = 6;
        } else if (isShortEvent) {
          fontSize = (eventHeight / 2);
        }

        final eventCell = DraggableEventCell(
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
    return (sizeOfOneMinute * durationInMinutes) - 2;
  }
}

class DraggableEventCell extends StatelessWidget {
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
  });

  EventCellContent _buildCellContent(Color textColor, Color backgroundColor) {
    return EventCellContent(
      event: event,
      isShortEvent: isShortEvent,
      fontSize: fontSize,
      height: height,
      width: width,
      textColor: textColor,
      backgroundColor: backgroundColor,
      separatorColor: separatorColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildCellContent(
      textColor,
      backgroundColor,
    );

    final contentWithColorInverted = _buildCellContent(
      textColorInverted,
      backgroundColorInverted,
    );

    return LongPressDraggable<Event>(
      data: event,
      hapticFeedbackOnStart: true,
      childWhenDragging: Container(
        height: height,
        width: width,
        color: Colors.orange[100],
      ),
      feedback: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          boxShadow: [
            new BoxShadow(
              color: contentWithColorInverted.backgroundColor.withOpacity(0.5),
              offset: new Offset(0, 5),
              blurRadius: 10,
            )
          ],
        ),
        child: contentWithColorInverted,
      ),
      child: content,
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
                event.title,
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
  static const double DEFAULT_HEIGHT = 16;

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
      height: DEFAULT_HEIGHT,
      width: double.infinity,
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
            child: Padding(
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
