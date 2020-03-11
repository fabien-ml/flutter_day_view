import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import './models/event.dart';
import './utils/date_time_extention.dart';
import './widgets/current_time_indicator.dart';
import './widgets/draggable_event_cell.dart';
import './widgets/hour_row.dart';

class DayView extends StatefulWidget {
  static const int HOURS_PER_DAY = 24;
  static const int MINUTES_PER_DAY = 1440;
  static const double EVENT_ROW_LEFT_OFFSET = 60;
  static const double BASE_TOP_OFFSET = 8;

  final DateTime selectedDate;
  final List<Event> events;
  final int sectionPerHour;
  final double hourRowHeight;
  final double scrollSpeed;

  DayView({
    @required this.selectedDate,
    @required this.events,
    this.sectionPerHour = 4,
    this.hourRowHeight = 60,
    this.scrollSpeed = 3,
  });

  @override
  _DayViewState createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  ScrollController _scrollController;
  List<Event> _events;
  bool _dragEventStarted = false;
  bool _isScrolling = false;

  int get _numberOfDragTarget {
    return DayView.HOURS_PER_DAY * widget.sectionPerHour;
  }

  double get _height {
    return this.widget.hourRowHeight * DayView.HOURS_PER_DAY;
  }

  double get _sizeOfOneMinute {
    return this._height / DayView.MINUTES_PER_DAY;
  }

  double get _minEventCellHeight {
    return widget.hourRowHeight / widget.sectionPerHour;
  }

  int get _minutesSection {
    return (60 / widget.sectionPerHour).truncate();
  }

  bool get _selectedDateIsToday {
    final now = DateTime.now();
    return now.year == widget.selectedDate.year &&
        now.month == widget.selectedDate.month &&
        now.day == widget.selectedDate.day;
  }

  @override
  void initState() {
    super.initState();
    _events = widget.events;

    final initialScrollOffset =
        _getTopPositionFromTimeInMinutes(DateTime.now().roundToMinutes()) - 100;
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
/*
    final today = DateTime.now();
    final screenSize = MediaQuery.of(context).size;
    final availableEventWidth = screenSize.width - DayView.EVENT_ROW_LEFT_OFFSET;

    final topScrollTriggerAreaHeight = screenSize.height * 0.1;
    final bottomScrollTriggerAreaHeight = screenSize.height * 0.2;
*/
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        final availableEventWidth =
            screenSize.width - DayView.EVENT_ROW_LEFT_OFFSET;

        final topScrollTriggerAreaHeight = screenSize.height * 0.1;
        final bottomScrollTriggerAreaHeight = screenSize.height * 0.2;

        return Listener(
          onPointerMove: (event) {
            if (!_dragEventStarted) {
              return;
            }

            final currentLocalYPosition = event.localPosition.dy;

            if (_isScrolling &&
                currentLocalYPosition > topScrollTriggerAreaHeight &&
                currentLocalYPosition <
                    context.size.height - bottomScrollTriggerAreaHeight) {
              _stopScroll();
              return;
            }

            if (_isScrolling) {
              return;
            }

            final scrollPosition = _scrollController.position;

            if (currentLocalYPosition < topScrollTriggerAreaHeight &&
                scrollPosition.pixels > scrollPosition.minScrollExtent) {
              _scrollToTop();
            } else if (currentLocalYPosition >
                    context.size.height - bottomScrollTriggerAreaHeight &&
                scrollPosition.pixels < scrollPosition.maxScrollExtent) {
              _scrollToBottom();
            }
          },
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Stack(
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        height: this._height + widget.hourRowHeight,
                        child: Column(
                          children: _buildHourRows(),
                        ),
                      ),
                      ..._buildPositionedEvents(availableEventWidth),
                      if (_selectedDateIsToday) _buildCurrentTimeIndicator(),
                      Positioned(
                        top: 0,
                        //DayView.BASE_TOP_OFFSET,
                        left: 16,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          child: Column(
                            children: List<Widget>.generate(_numberOfDragTarget,
                                (index) {
                              final targetDateTime = _getDateTimeFromTopOffset(
                                  index * _minEventCellHeight + 8);
                              return Container(
                                height: _minEventCellHeight,
                                child: DragTarget<Event>(
                                  builder: (context, candidates, rejects) {
                                    return candidates.isNotEmpty
                                        ? Container(
                                            child: Text(
                                              DateFormat.Hm()
                                                  .format(targetDateTime),
                                              style: TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          )
                                        : null;
                                  },
                                  onAccept: (event) {
                                    _updateEvent(event.id, targetDateTime);
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
          ),
        );
      },
    );
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

  void _updateIsScrolling(bool newValue) {
    setState(() {
      _isScrolling = newValue;
    });
  }

  void _scrollToTop() {
    _updateIsScrolling(true);
    final distance = _scrollController.position.pixels -
        _scrollController.position.minScrollExtent;
    final millis = (distance * widget.scrollSpeed).round();
    _scrollController
        .animateTo(_scrollController.position.minScrollExtent,
            duration: Duration(milliseconds: millis), curve: Curves.easeInOut)
        .then((_) {
      _updateIsScrolling(false);
    });
  }

  void _scrollToBottom() {
    _updateIsScrolling(true);
    final distance = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    final millis = (distance * widget.scrollSpeed).round();
    _scrollController
        .animateTo(_scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: millis), curve: Curves.easeInOut)
        .then((_) {
      _updateIsScrolling(false);
    });
    ;
  }

  void _stopScroll() {
    _scrollController.jumpTo(_scrollController.position.pixels);
    _updateIsScrolling(false);
  }

  Widget _buildCurrentTimeIndicator() {
    final now = DateTime.now();

    return Positioned(
      top: _getTopPositionFromTimeInMinutes(now.roundToMinutes()),
      left: 20,
      right: 0,
      child: CurrentTimeIndicator(
        date: now,
      ),
    );
  }

  DateTime _getDateTimeFromTopOffset(double offset) {
    double totalMinutes = ((offset * DayView.MINUTES_PER_DAY) / _height);
    int hour = (totalMinutes / 60).truncate();
    int minutes =
        ((totalMinutes % 60) - ((totalMinutes % 60) % _minutesSection))
            .truncate();
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minutes, 0);
  }

  void _updateEvent(String eventId, DateTime newStartDate) {
    Event event = _events.firstWhere((it) => it.id == eventId);

    if (event == null) {
      return;
    }

    if (event.startDate == newStartDate) {
      return;
    }

    final duration = event.endDate.difference(event.startDate);
    final newEndDate = newStartDate.add(duration);
    setState(() {
      _events.removeWhere((it) => it.id == event.id);
      _events.add(event.copyWith(
        startDate: newStartDate,
        endDate: newEndDate,
      ));
    });
  }

  List<Widget> _buildHourRows() {
    List<Widget> hourRows = [];

    DateTime selectedDateAtStartOfDay = DateTime(widget.selectedDate.year,
        widget.selectedDate.month, widget.selectedDate.day, 0, 0, 0);

    for (var i = 0; i < DayView.HOURS_PER_DAY; i++) {
      DateTime selectedDateAtStartOfDayPlusXHours =
          selectedDateAtStartOfDay.add(Duration(hours: i));

      hourRows.add(Container(
        height: this.widget.hourRowHeight,
        child: HourRow(
          hourLabel: DateFormat.Hm().format(selectedDateAtStartOfDayPlusXHours),
          showHourLabel: _selectedDateIsToday
              ? _shouldShowRowHour(selectedDateAtStartOfDayPlusXHours)
              : true,
        ),
      ));
    }

    DateTime nextDateAtStartOfDay =
        selectedDateAtStartOfDay.add(Duration(days: 1));

    hourRows.add(HourRow(
      hourLabel: DateFormat.Hm().format(nextDateAtStartOfDay),
      showHourLabel: _selectedDateIsToday
          ? _shouldShowRowHour(nextDateAtStartOfDay)
          : true,
    ));

    return hourRows;
  }

  bool _shouldShowRowHour(DateTime date) {
    double safeAreaHeight = _minEventCellHeight;

    int difference = (date.difference(DateTime.now()).inMinutes.abs() * _sizeOfOneMinute).round();
    return difference > safeAreaHeight;
  }

  List<Positioned> _buildPositionedEvents(double rowWidth) {
    List<Positioned> positionedEvents = [];

    SplayTreeMap<int, List<Event>> eventsGroups =
        SplayTreeMap((a, b) => a.compareTo(b));

    _events.forEach((event) {
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

        final topOffset = DayView.BASE_TOP_OFFSET +
            1 +
            _getTopPositionFromTimeInMinutes(event.startDate.roundToMinutes());

        final baseEventHeight =
            _getEventHeightFromDuration(event.durationInMinutes) - 2;

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
            left: DayView.EVENT_ROW_LEFT_OFFSET + (eventWidth * index) + indent,
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

  int _getNumberOfSuperposedEvents(
      SplayTreeMap<int, List<Event>> eventsGroups, Event targetEvent) {
    return eventsGroups.values
        .expand((group) => group.toList())
        .where((event) =>
            event.startDate.isBefore(targetEvent.startDate) &&
            event.endDate.isAfter(targetEvent.startDate))
        .where(
            (event) => _getKeyForEvent(event) != _getKeyForEvent(targetEvent))
        .length;
  }

  int _getKeyForEvent(Event event) {
    // key is start time floored to nearest wanted minutes section
    // ex for round to quarter hour : 01:27 -> 01:15 -> 75
    return event.startDate
        .floorToNearestMinutesSection(_minutesSection)
        .roundToMinutes();
  }

  double _getTopPositionFromTimeInMinutes(int timeInMinutes) {
    return (timeInMinutes * this._height) / DayView.MINUTES_PER_DAY;
  }

  double _getEventHeightFromDuration(int durationInMinutes) {
    return (_sizeOfOneMinute * durationInMinutes);
  }
}
