import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import './current_time_indicator.dart';
import './draggable_event_cell.dart';
import './hour_row.dart';
import '../models/event.dart';
import '../utils/date_time_extention.dart';

class ScheduleView extends StatefulWidget {
  final List<Event> events;
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
    final dayCountBetweenStartDateAndToday = widget.startDate.difference(DateTime.now()).inDays.abs();
    return (dayCountBetweenStartDateAndToday / widget.daysPerPage).round();
  }

  double get _currentTimeScrollOffset {
    return _getTopPositionFromTimeInMinutes(DateTime.now().roundToMinutes()) - 100;
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
    _scrollController = ScrollController(initialScrollOffset: _currentTimeScrollOffset);
    _pageController = PageController(initialPage: _pageOfToday);
    _pageDates = _getDatesForPage(_pageOfToday, widget.daysPerPage, widget.startDate);
  }

  @override
  void didUpdateWidget(ScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.daysPerPage != widget.daysPerPage) {
      int dayCountBetweenStartDateAndPageFirstDate = widget.startDate.difference(_pageDates.first).inDays.abs();
      final newPageIndex = (dayCountBetweenStartDateAndPageFirstDate / widget.daysPerPage).round();
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
        final dayColumnWidth = (parentSize.width - PAGE_LEFT_MARGIN) / widget.daysPerPage;

        return Listener(
          child: Column(
            children: <Widget>[
              Container(
                width: (parentSize.width - PAGE_LEFT_MARGIN),
                height: 100,
                margin: EdgeInsets.only(left: PAGE_LEFT_MARGIN),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _buildPageDatesAndAllDayEvents(),
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
                                children: _buildPageContent(pageIndex, dayColumnWidth),
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
      _pageDates = _getDatesForPage(pageIndex, widget.daysPerPage, widget.startDate);
    });
  }

  List<Widget> _buildPageDatesAndAllDayEvents() {
    return _pageDates.map((date) {
      return Flexible(
        flex: 1,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(DateFormat("dd-MM").format(date)),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _buildAllDayEvents(date),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPageContent(int pageIndex, double columnWidth) {
    return _getDatesForPage(pageIndex, widget.daysPerPage, widget.startDate).map((date) {
      return _buildDayView(date, columnWidth);
    }).toList();
  }

  List<DateTime> _getDatesForPage(int pageIndex, int daysPerPage, DateTime startDate) {
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
          ..._buildPositionedEvents(date, width),
          Positioned.fill(
            child: Column(
              children: _buildDragTarget(date, width),
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

  List<Widget> _buildDragTarget(DateTime date, double width) {
    return List<Widget>.generate(_numberOfDragTarget, (index) {
      final targetDateTime = _getTimeFromTopOffsetForDate(date, index * _minEventCellHeight + 8);
      return Container(
        height: _minEventCellHeight,
        width: width,
        child: DragTarget<Event>(
          builder: (context, candidates, rejects) {
            return candidates.isNotEmpty
                ? Container(
                    child: HourRow(
                      hourLabel: DateFormat.Hm().format(targetDateTime),
                      showHourLabel: true,
                      color: Colors.blue,
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

  List<Widget> _buildAllDayEvents(DateTime date) {
    return _getEventFromDate(date).where((event) => event.allDay).map((event) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(8),
        color: Colors.blueGrey,
        child: Text(
          event.title,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      );
    }).toList();
  }

  List<Event> _getEventFromDate(DateTime date) {
    return widget.events.where((event) {
      if (event.allDay) {
        return _isSameDay(event.startDate, date);
      }

      final isStartOrEndThisDay = _isSameDay(event.startDate, date) || _isSameDay(event.endDate, date);
      final isDuringAllThisDay = event.startDate.isBefore(date) && event.endDate.isAfter(date);

      return isStartOrEndThisDay || isDuringAllThisDay;
    }).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
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
    int minutes =
        ((totalMinutes % MINUTES_PER_HOUR) - ((totalMinutes % MINUTES_PER_HOUR) % _minutesPerSection)).truncate();
    return DateTime(date.year, date.month, date.day, hour, minutes, 0);
  }

  // Layout algorithm

  List<Positioned> _buildPositionedEvents(DateTime date, double rowWidth) {
    return _layoutEventsForDate(date, rowWidth).map((eventCell) {
      double topOffset = BASE_TOP_OFFSET + 1;

      final isSameDay = _isSameDay(date, eventCell.event.startDate);

      if (isSameDay) {
        topOffset += _getTopPositionFromTimeInMinutes(eventCell.event.startDate.roundToMinutes());
      }

      final eventHeightWhenDragging = eventCell.height - 1;
      double baseEventHeight = eventHeightWhenDragging;

      if (!isSameDay) {
        DateTime dateAtStartOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
        final difference = eventCell.event.startDate.difference(dateAtStartOfDay).inMinutes.abs();
        baseEventHeight -= _durationToHeight(difference);
      }

      final eventHeight = baseEventHeight < _minEventCellHeight ? _minEventCellHeight : baseEventHeight;

      final isShortEvent = eventHeight <= _minEventCellHeight;

      double fontSize = 12;

      if (isShortEvent && (eventHeight / 2) < 6) {
        fontSize = 6;
      } else if (isShortEvent) {
        fontSize = (eventHeight / 2);
      }

      final eventCellWidget = DraggableEventCell(
        event: eventCell.event,
        isShortEvent: isShortEvent,
        fontSize: fontSize,
        width: eventCell.width,
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

      return Positioned(
        left: eventCell.left,
        top: topOffset,
        height: eventHeight,
        width: eventCell.width,
        child: eventCellWidget,
      );
    }).toList();
  }

  List<EventCell> _layoutEventsForDate(DateTime date, double rowWidth) {
    List<EventCell> positionedEventCells = [];
    List<List<Event>> columns = [];
    DateTime lastEventEnding;

    // Create an array of all events
    List<Event> events = _getEventFromDate(date).where((event) => !event.allDay).toList();

    // Sort it by starting time, and then by ending time.
    List<Event> sortedEvents = events
      ..sort((event1, event2) {
        if (event1.startDate.isBefore(event2.startDate)) {
          return -1;
        }

        if (event1.startDate.isAfter(event2.startDate)) {
          return 1;
        }

        if (event1.endDate.isBefore(event2.endDate)) {
          return -1;
        }

        if (event1.endDate.isAfter(event2.endDate)) {
          return 1;
        }

        return 0;
      });

    // Iterate over the sorted array
    sortedEvents.forEach((event) {
      final startDate = event.startDate;

      if (lastEventEnding != null &&
          (startDate.isAfter(lastEventEnding) || startDate.isAtSameMomentAs(lastEventEnding))) {
        positionedEventCells.addAll(_packEvents(columns, rowWidth));
        columns = [];
        lastEventEnding = null;
      }

      bool placed = false;

      for (var i = 0; i < columns.length; i++) {
        List<Event> column = columns[i];

        if (!_collidesWidth(column.last, event)) {
          column.add(event);
          placed = true;
          break;
        }
      }

      if (!placed) {
        columns.add([event]);
      }

      if (lastEventEnding == null || event.endDate.isAfter(lastEventEnding)) {
        lastEventEnding = event.endDate;
      }
    });

    if (columns.isNotEmpty) {
      positionedEventCells.addAll(_packEvents(columns, rowWidth));
    }

    return positionedEventCells;
  }

  List<EventCell> _packEvents(List<List<Event>> columns, double rowWidth) {
    List<EventCell> eventCells = [];

    int columnCount = columns.length;

    for (var i = 0; i < columnCount; i++) {
      List<Event> column = columns[i];

      for (var j = 0; j < column.length; j++) {
        Event event = column[j];

        final colSpan = _expandEvent(event, i, columns);
        final leftOffsetPercent = (i / columnCount) * 100;

        eventCells.add(
          EventCell(
            event: event,
            top: _getTopPositionFromTimeInMinutes(event.startDate.roundToMinutes()),
            left: (leftOffsetPercent * rowWidth) / 100,
            height: _durationToHeight(event.durationInMinutes),
            width: rowWidth * colSpan / columnCount - 1,
          ),
        );
      }
    }

    return eventCells;
  }

  bool _collidesWidth(Event event1, Event event2) {
    return event1.endDate.isAfter(event2.startDate) && event1.startDate.isBefore(event2.endDate);
  }

  int _expandEvent(Event event1, int columnIndex, List<List<Event>> columns) {
    int colSpan = 1;

    for (var i = columnIndex + 1; i < columns.length; i++) {
      List<Event> column = columns[i];

      for (var j = 0; j < column.length; j++) {
        Event event2 = column[j];

        if (_collidesWidth(event1, event2)) {
          return colSpan;
        }
      }
      colSpan++;
    }

    return colSpan;
  }
}

class EventCell {
  Event event;
  double top;
  double left;
  double height;
  double width;

  EventCell({
    @required this.event,
    @required this.top,
    @required this.left,
    @required this.height,
    @required this.width,
  });
}
