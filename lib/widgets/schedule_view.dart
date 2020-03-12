import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import './current_time_indicator.dart';
import './draggable_event_cell.dart';
import './hour_row.dart';
import '../models/schedule_view_event.dart';
import '../utils/date_time_extention.dart';

class ScheduleView extends StatefulWidget {
  final List<ScheduleViewEvent> events;
  final DateTime startDate;
  final DateTime endDate;
  final int daysPerPage;
  final int sectionPerHour;
  final double hourRowHeight;
  final double allDaySectionHeight;
  final double scrollSpeed;
  final Function(String eventId, DateTime targetStartDate) onEventDragCompleted;

  ScheduleView({
    @required this.events,
    @required this.startDate,
    @required this.endDate,
    @required this.onEventDragCompleted,
    this.daysPerPage = 1,
    this.sectionPerHour = 4,
    this.hourRowHeight = 64,
    this.allDaySectionHeight = 200,
    this.scrollSpeed = 3,
  });

  @override
  _ScheduleViewState createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  static const int HOURS_PER_DAY = 24;
  static const int MINUTES_PER_DAY = 1440;
  static const int MINUTES_PER_HOUR = 60;
  static const double PAGE_LEFT_MARGIN = 60;
  static const double BASE_TOP_OFFSET = 8;

  ScrollController _scrollController;
  PageController _pageController;
  int _pageCount;
  List<DateTime> _pageDates;
  bool _dragEventStarted;

  int get _pageOfToday {
    final dayCountBetweenStartDateAndToday =
        widget.startDate.difference(DateTime.now()).inDays.abs();
    return (dayCountBetweenStartDateAndToday / widget.daysPerPage).round();
  }

  double get _currentTimeScrollOffset {
    return _getTopPositionFromTimeInMinutes(DateTime.now().roundToMinutes()) -
        100;
  }

  double get _pageHeight {
    return this.widget.hourRowHeight * HOURS_PER_DAY;
  }

  double get _oneMinuteHeight {
    return this._pageHeight / MINUTES_PER_DAY;
  }

  double get _minEventCellHeight {
    return widget.hourRowHeight / widget.sectionPerHour;
  }

  int get _minutesPerSection {
    return (MINUTES_PER_HOUR / widget.sectionPerHour).truncate();
  }

  int get _numberOfDragTarget {
    return HOURS_PER_DAY * widget.sectionPerHour;
  }

  @override
  void initState() {
    super.initState();
    _dragEventStarted = false;
    _initPageCount();
    _scrollController =
        ScrollController(initialScrollOffset: _currentTimeScrollOffset);
    _pageController = PageController(initialPage: _pageOfToday);
    _pageDates =
        _getDatesForPage(_pageOfToday, widget.daysPerPage, widget.startDate);
  }

  @override
  void didUpdateWidget(ScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.daysPerPage != widget.daysPerPage) {
      int dayCountBetweenStartDateAndPageFirstDate =
          widget.startDate.difference(_pageDates.first).inDays.abs();
      final newPageIndex =
          (dayCountBetweenStartDateAndPageFirstDate / widget.daysPerPage)
              .round();
      print(
          "$dayCountBetweenStartDateAndPageFirstDate / ${widget.daysPerPage} = $newPageIndex");
      _pageController.jumpToPage(newPageIndex);
      _updatePageDates(newPageIndex);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (layoutBuilderContext, constraints) {
        final parentSize = Size(constraints.maxWidth, constraints.maxHeight);
        final columnWidth =
            (parentSize.width - PAGE_LEFT_MARGIN) / widget.daysPerPage;

        return Listener(
          child: Column(
            children: <Widget>[
              Container(
                width: (parentSize.width - PAGE_LEFT_MARGIN),
                margin: EdgeInsets.only(left: PAGE_LEFT_MARGIN),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _buildPageDates(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Container(
                    width: double.infinity,
                    height: _pageHeight + 17 + 16,
                    padding: EdgeInsets.only(top: 16),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Column(
                            children: _buildHourRows(),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          right: 0,
                          left: PAGE_LEFT_MARGIN,
                          child: PageView.builder(
                            onPageChanged: _updatePageDates,
                            controller: _pageController,
                            itemCount: _pageCount,
                            itemBuilder: (pageViewContext, pageIndex) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    _buildPageContent(pageIndex, columnWidth),
                              );
                            },
                          ),
                        ),
                        _buildCurrentTimeIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updatePageDates(int pageIndex) {
    setState(() {
      _pageDates =
          _getDatesForPage(pageIndex, widget.daysPerPage, widget.startDate);
    });
  }

  List<Widget> _buildPageDates() {
    return _pageDates.map((date) {
      return Flexible(
        flex: 1,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(DateFormat("EEE").format(date)),
              Text(DateFormat("dd").format(date)),
              Text(DateFormat("MM").format(date)),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPageContent(int pageIndex, double columnWidth) {
    return _getDatesForPage(pageIndex, widget.daysPerPage, widget.startDate)
        .map((date) {
      return _buildDayView(date, columnWidth);
    }).toList();
  }

  List<DateTime> _getDatesForPage(
      int pageIndex, int daysPerPage, DateTime startDate) {
    return List<DateTime>.generate(daysPerPage, (i) {
      return startDate.add(Duration(days: (pageIndex * daysPerPage) + i));
    });
  }

  Widget _buildDayView(DateTime date, double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey)),
      ),
      child: Stack(
        children: <Widget>[
          ..._buildPositionedEvents2(date, width),
          Positioned(
            top: 0,
            left: 16,
            right: 0,
            bottom: 0,
            child: Container(
              child: Column(children: _buildDragTarget(date, width)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHourRows() {
    List<Widget> hourRows = [];

    final now = DateTime.now();
    DateTime hour = DateTime(now.year, now.month, now.day, 0, 0, 0);

    for (var i = 0; i < HOURS_PER_DAY; i++) {
      hourRows.add(Container(
        height: this.widget.hourRowHeight,
        child: HourRow(
          hourLabel: DateFormat.Hm().format(hour),
          showHourLabel: _shouldShowRowHour(hour),
        ),
      ));

      hour = hour.add(Duration(hours: 1));
    }

    hourRows.add(HourRow(
      hourLabel: DateFormat.Hm().format(hour),
      showHourLabel: _shouldShowRowHour(hour),
    ));

    return hourRows;
  }

  Widget _buildCurrentTimeIndicator() {
    final now = DateTime.now();

    return Positioned(
      top: _getTopPositionFromTimeInMinutes(now.roundToMinutes()),
      left: 16,
      right: 0,
      child: CurrentTimeIndicator(
        date: now,
      ),
    );
  }

  Map<int, int> _getOverlapingEventCountPerHourForDate(DateTime date) {
    final sortedEventsFromDate = _getEventFromDate(date)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    var startPeriod = DateTime(date.year, date.month, date.day, 0, 0, 0);
    var endPeriod = startPeriod.add(Duration(hours: 1));

    Map<int, int> overlapingEventCountPerHour = {};

    for (var i = 0; i < HOURS_PER_DAY; i++) {
      final overlapingEvents = sortedEventsFromDate.where((event) {
        return _isOverlaping(
            startPeriod, endPeriod, event.startDate, event.endDate);
      });


      overlapingEventCountPerHour[startPeriod.hour] = overlapingEvents.length;

      startPeriod = startPeriod.add(Duration(hours: 1));
      endPeriod = startPeriod.add(Duration(hours: 1));
    }

    return overlapingEventCountPerHour;
  }

  void _getEventWidthRatio1(DateTime date) {
    final sortedEventsFromDate = _getEventFromDate(date)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    Map<ScheduleViewEvent, int> eventWithMaxOverlaping = {};

    sortedEventsFromDate.forEach((event1) {
      Map<int, int> overlapingPerHour = {};

      sortedEventsFromDate.forEach((event2) {
        if (event1.id == event2.id) {
          return;
        }

        if (!_isOverlaping(event1.startDate, event1.endDate, event2.startDate,
            event2.endDate)) {
          return;
        }

        final overlapingHour = event1.startDate.isAfter(event2.startDate)
            ? event1.startDate.hour
            : event2.startDate.hour;

        if (overlapingPerHour.containsKey(overlapingHour)) {
          overlapingPerHour[overlapingHour] += 1;
        } else {
          overlapingPerHour[overlapingHour] = 1;
        }
      });

      eventWithMaxOverlaping[event1] = overlapingPerHour.values.isNotEmpty
          ? overlapingPerHour.values.reduce(max)
          : 0;
    });

  }

  Map<ScheduleViewEvent, int> _getEventAndWidthRatio2(DateTime date) {
    final sortedEventsFromDate = _getEventFromDate(date)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final overlapingCountPerHour = _getOverlapingEventCountPerHourForDate(date);

    Map<ScheduleViewEvent, int> eventWithMaxOverlaping = {};

    sortedEventsFromDate.forEach((event) {
      eventWithMaxOverlaping[event] = 0;

      final max = event.endDate.minute == 0 ? event.endDate.hour : event.endDate.hour + 1;

      for (var i = event.startDate.hour; i < max; i++) {
        if (overlapingCountPerHour.containsKey(i) && overlapingCountPerHour[i] > eventWithMaxOverlaping[event]) {
          eventWithMaxOverlaping[event] = overlapingCountPerHour[i];
        }
      }
    });

    return eventWithMaxOverlaping;
  }

  List<Positioned> _buildPositionedEvents(DateTime date, double rowWidth) {
    List<Positioned> positionedEvents = [];

    SplayTreeMap<int, List<ScheduleViewEvent>> eventsGroups =
        SplayTreeMap((a, b) => a.compareTo(b));

    _getEventFromDate(date).forEach((event) {
      final key = _getKeyForEvent(event);

      if (eventsGroups.containsKey(key)) {
        eventsGroups[key].add(event);
      } else {
        eventsGroups[key] = [event];
      }
    });

    eventsGroups.values.forEach((eventList) {
      int index = 0;

      eventList.sort((a, b) => a.startDate.compareTo(b.startDate));

      eventList.forEach((event) {
        final int numberOfSuperposedEvents =
            _getNumberOfSuperposedEvents(eventsGroups, event);

        final indent = numberOfSuperposedEvents * 5;

        final eventWidth = (rowWidth / eventList.length) - indent;

        double topOffset = BASE_TOP_OFFSET + 1;

        final isSameDay = _isSameDay(date, event.startDate);

        if (isSameDay) {
          topOffset += _getTopPositionFromTimeInMinutes(
              event.startDate.roundToMinutes());
        }

        final eventHeightWhenDragging =
            _durationToHeight(event.durationInMinutes) - 2;
        double baseEventHeight = eventHeightWhenDragging;

        if (!isSameDay) {
          DateTime dateAtStartOfDay =
              DateTime(date.year, date.month, date.day, 0, 0, 0);
          final difference =
              event.startDate.difference(dateAtStartOfDay).inMinutes.abs();
          baseEventHeight -= _durationToHeight(difference);
        }

        final eventHeight = baseEventHeight < _minEventCellHeight
            ? _minEventCellHeight
            : baseEventHeight;

        final isShortEvent = eventHeight <= _minEventCellHeight;

        double fontSize = 12;

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
          heightWhenDragging: eventHeightWhenDragging,
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
            left: (eventWidth * index) + indent,
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

  List<Positioned> _buildPositionedEvents2(DateTime date, double rowWidth) {

    Map<int, int> remainingEventToPositionedPerHour = _getOverlapingEventCountPerHourForDate(date);
    Map<int, int> eventCountPerHour = _getOverlapingEventCountPerHourForDate(date);

    Map<int, double> availableWidthForHour = {};

    for (var i = 0; i < HOURS_PER_DAY; i++) {
      availableWidthForHour[i] = rowWidth;
    }

    List<Positioned> positionedEvents = [];
    final eventsWithWidthRatio = _getEventAndWidthRatio2(date);

    eventsWithWidthRatio.forEach((event, widthDivider) {

      int position = (eventCountPerHour[event.startDate.hour] / remainingEventToPositionedPerHour[event.startDate.hour]).round();

      print("${event.title} : $position");

      double eventWidth = rowWidth / widthDivider;

      final max = event.endDate.minute == 0 ? event.endDate.hour : event.endDate.hour + 1;

      double allAvailableSpace = rowWidth;

      bool shouldTakeAllAvailableSpace = true;

      for(var i = event.startDate.hour; i < max; i++) {

        if(remainingEventToPositionedPerHour[i] > 1) {
          shouldTakeAllAvailableSpace = false;
        }

        if(remainingEventToPositionedPerHour[i] == 1 && availableWidthForHour[i] < allAvailableSpace){
            allAvailableSpace = availableWidthForHour[i];
        }

        if(remainingEventToPositionedPerHour[i] > 0) {
          remainingEventToPositionedPerHour[i] -= 1;
        }
      }

      if (shouldTakeAllAvailableSpace) {
        eventWidth = allAvailableSpace;
      }

      double topOffset = BASE_TOP_OFFSET + 1;

      final isSameDay = _isSameDay(date, event.startDate);

      if (isSameDay) {
        topOffset +=
            _getTopPositionFromTimeInMinutes(event.startDate.roundToMinutes());
      }

      final eventHeightWhenDragging =
          _durationToHeight(event.durationInMinutes) - 2;
      double baseEventHeight = eventHeightWhenDragging;

      if (!isSameDay) {
        DateTime dateAtStartOfDay =
            DateTime(date.year, date.month, date.day, 0, 0, 0);
        final difference =
            event.startDate.difference(dateAtStartOfDay).inMinutes.abs();
        baseEventHeight -= _durationToHeight(difference);
      }

      final eventHeight = baseEventHeight < _minEventCellHeight
          ? _minEventCellHeight
          : baseEventHeight;

      final isShortEvent = eventHeight <= _minEventCellHeight;

      double fontSize = 12;

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
        heightWhenDragging: eventHeightWhenDragging,
        textColor: Colors.blue[800],
        backgroundColor: Colors.blue[100].withOpacity(0.7),
        textColorInverted: Colors.white,
        backgroundColorInverted: Colors.blue[500],
        separatorColor: Colors.blue[500],
        dragStartHandler: _onDragEventStart,
        dragEndHandler: _onDragEventEnd,
      );

      final availabledWidth = availableWidthForHour[event.startDate.hour];

      double leftOffset = rowWidth - availabledWidth;

      positionedEvents.add(
        Positioned(
          left: leftOffset,
          top: topOffset,
          height: eventHeight,
          width: eventWidth - 2,
          child: eventCell,
        ),
      );

      for(var i = event.startDate.hour; i < max; i++) {
        availableWidthForHour[i] = availabledWidth - eventWidth;
      }

    });

    return positionedEvents;
  }

  List<Widget> _buildDragTarget(DateTime date, double width) {
    return List<Widget>.generate(_numberOfDragTarget, (index) {
      final targetDateTime =
          _getTimeFromTopOffsetForDate(date, index * _minEventCellHeight + 8);
      return Container(
        height: _minEventCellHeight,
        width: width,
        child: DragTarget<ScheduleViewEvent>(
          builder: (context, candidates, rejects) {
            return candidates.isNotEmpty
                ? Container(
                    child: Text(
                      DateFormat.Hm().format(targetDateTime),
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  )
                : null;
          },
          onAccept: (event) {
            widget.onEventDragCompleted(event.id, targetDateTime);
          },
        ),
      );
    }).toList();
  }

  List<ScheduleViewEvent> _getEventFromDate(DateTime date) {
    return widget.events
        .where((event) =>
            _isSameDay(event.startDate, date) ||
            _isSameDay(event.endDate, date))
        .toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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

  int _getNumberOfSuperposedEvents(
      SplayTreeMap<int, List<ScheduleViewEvent>> eventsGroups,
      ScheduleViewEvent targetEvent) {
    return eventsGroups.values
        .expand((group) => group.toList())
        .where((event) =>
            event.startDate.isBefore(targetEvent.startDate) &&
            event.endDate.isAfter(targetEvent.startDate))
        .where(
            (event) => _getKeyForEvent(event) != _getKeyForEvent(targetEvent))
        .length;
  }

  /*
    key is start time floored to nearest wanted minutes section
    ex for round to quarter hour : 01:27 -> 01:15 -> 75
  */
  int _getKeyForEvent(ScheduleViewEvent event) {
    return event.startDate
        .floorToNearestMinutesSection(_minutesPerSection)
        .roundToMinutes();
  }

  double _durationToHeight(int durationInMinutes) {
    return durationInMinutes * _oneMinuteHeight;
  }

  void _initPageCount() {
    final dayCount = widget.startDate.difference(widget.endDate).inDays.abs();
    _pageCount = (dayCount / widget.daysPerPage).round();
  }

  double _getTopPositionFromTimeInMinutes(int timeInMinutes) {
    return (timeInMinutes * this._pageHeight) / MINUTES_PER_DAY;
  }

  bool _shouldShowRowHour(DateTime date) {
    double safeAreaHeight = _minEventCellHeight;
    int minutesBetweenNow = date.difference(DateTime.now()).inMinutes.abs();
    double difference = minutesBetweenNow * _oneMinuteHeight;
    return difference > safeAreaHeight;
  }

  DateTime _getTimeFromTopOffsetForDate(DateTime date, double offset) {
    double totalMinutes = ((offset * MINUTES_PER_DAY) / _pageHeight);
    int hour = (totalMinutes / MINUTES_PER_HOUR).truncate();
    int minutes = ((totalMinutes % MINUTES_PER_HOUR) -
            ((totalMinutes % MINUTES_PER_HOUR) % _minutesPerSection))
        .truncate();
    return DateTime(date.year, date.month, date.day, hour, minutes, 0);
  }

  bool _isOverlaping(DateTime startDate1, DateTime endDate1,
      DateTime startDate2, DateTime endDate2) {
    return startDate1.isBefore(endDate2) && startDate2.isBefore(endDate1);
  }
}
