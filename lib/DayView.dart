import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayView extends StatefulWidget {
  static const int HOURS_PER_DAY = 24;
  static const int MINUTES_PER_DAY = 1440;
  static const double DEFAULT_HOUR_ROW_HEIGHT = 60;
  static const double DEFAULT_MIN_EVENT_HEIGHT = DEFAULT_HOUR_ROW_HEIGHT / 6;
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
      Event("2", DateTime(now.year, now.month, now.day, 14, 42, 0),
          DateTime(now.year, now.month, now.day, 14, 55, 0), false, "Event 2"),
      Event("3", DateTime(now.year, now.month, now.day, 10, 15, 0),
          DateTime(now.year, now.month, now.day, 10, 30, 0), false, "Event 3"),
      Event("4", DateTime(now.year, now.month, now.day, 10, 30, 0),
          DateTime(now.year, now.month, now.day, 10, 45, 0), false, "Event 4"),
      Event("5",
          DateTime(now.year, now.month, now.day, 10, 45, 0),
          DateTime(now.year, now.month, now.day, 11, 0, 0),
          false,
          "Event 5 lorem ipsum dolor sit amet"),
      Event("6",
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
    ];

    SplayTreeMap<int, List<Event>> groupedEvents =
        SplayTreeMap((a, b) => a.compareTo(b));

    events.forEach((event) {
      if (groupedEvents.containsKey(event.startTimeInMinutes)) {
        groupedEvents[event.startTimeInMinutes].add(event);
      } else {
        groupedEvents[event.startTimeInMinutes] = [event];
      }
    });
    
    groupedEvents.values.forEach((eventList) {
      final eventWidth = rowWidth / eventList.length;
      int index = 0;

      eventList.sort((a, b) => a.startDate.compareTo(b.startDate));

      eventList.forEach((event) {

        final int indent = groupedEvents.values.expand((it) => it.toList()).where((it) {
          if(it.id == event.id) {
            return false;
          } else if(it.startTimeInMinutes == event.startTimeInMinutes) {
            return false;
          } else if(it.startDate.isBefore(event.startDate) && it.endDate.isAfter(event.endDate)) {
            return true;
          } else if(it.endDate.isAfter(event.startDate) && it.startDate.isBefore(event.startDate)) {
            return true;
          }
          return false;
        }).length;

        print("${event.id} -> $indent");

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

        positionedEvents.add(Positioned(
          left: DayView.DEFAULT_EVENT_ROW_LEFT_OFFSET + (eventWidth * index) + (indent * 5),
          top: topOffset,
          height: eventHeight,
          width: eventWidth,
          child: Container(
            color: Colors.blue[100].withOpacity(0.7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 1,
                  color: Colors.blue[500],
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
                        color: Colors.blue[800],
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ));
        index++;
      });
    });

    return positionedEvents;
  }

  double _getTopPositionFromDateTime(DateTime date) {
    double minutes = date.minute + (date.hour * 60.0);
    return (minutes * this.height) / DayView.MINUTES_PER_DAY;
  }

  double _getEventHeightFromDuration(int durationInMinutes) {
    return (sizeOfOneMinute * durationInMinutes) - 2;
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

  int get startTimeInMinutes {
    int min = 0;

    if (startDate.minute < 10) {
      min = 0;
    } else {
      int minToSubstract = (startDate.minute % 10.0).abs().round();
      min = startDate.subtract(Duration(minutes: minToSubstract)).minute;
    }

    return (startDate.hour * 60) + min;
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
