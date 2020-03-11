import 'dart:collection';

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

  ScheduleView({
    @required this.events,
    @required this.startDate,
    @required this.endDate,
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

  @override
  void initState() {
    super.initState();
    _dragEventStarted = false;
    _initPageCount();
    _scrollController =
        ScrollController(initialScrollOffset: _currentTimeScrollOffset);
    _pageController = PageController(initialPage: _pageOfToday);
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
        final columnWidth = (parentSize.width - PAGE_LEFT_MARGIN) / widget.daysPerPage;

        return Listener(
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
                      controller: _pageController,
                      itemCount: _pageCount,
                      itemBuilder: (pageViewContext, pageIndex) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildPageContent(pageIndex, columnWidth),
                        );
                      },
                    ),
                  ),
                  _buildCurrentTimeIndicator(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPageContent(int pageIndex, double columnWidth) {
    return List<Widget>.generate(widget.daysPerPage, (columnIndex) {
      final date = widget.startDate
          .add(Duration(days: (pageIndex * widget.daysPerPage) + columnIndex));
      return _buildDayView(date, columnWidth);
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
          ..._buildPositionedEvents(date, width),
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

  List<Positioned> _buildPositionedEvents(DateTime date, double rowWidth) {
    List<Positioned> positionedEvents = [];

    SplayTreeMap<int, List<ScheduleViewEvent>> eventsGroups =
        SplayTreeMap((a, b) => a.compareTo(b));

    _getEventInDate(date).forEach((event) {
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

  List<ScheduleViewEvent> _getEventInDate(DateTime date) {
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _shouldShowRowHour(DateTime date) {
    double safeAreaHeight = _minEventCellHeight;
    int minutesBetweenNow = date.difference(DateTime.now()).inMinutes.abs();
    double difference = minutesBetweenNow * _oneMinuteHeight;
    return difference > safeAreaHeight;
  }
}
