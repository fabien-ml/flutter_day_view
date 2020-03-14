import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    this.scrollSpeed = 3,
  });

  @override
  _ScheduleViewState createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  static const int HOURS_PER_DAY = 24;
  static const int MINUTES_PER_DAY = 1440;
  static const int MINUTES_PER_HOUR = 60;
  static const double HOUR_ROW_LABEL_LEFT_MARGIN = 60;
  static const double BASE_TOP_OFFSET = 8;

  ScrollController _verticalScrollController;
  PageController _pageController;
  int _pageCount;
  bool _dragEventStarted;
  List<DateTime> _visibleDates;

  int get _todayPage {
    final dayCountBetweenStartDateAndToday = widget.startDate.difference(DateTime.now()).inDays.abs();
    return (dayCountBetweenStartDateAndToday / widget.daysPerPage).round();
  }

  double get _currentTimeScrollOffset {
    return _getYOffsetFromTimeInMinutes(DateTime.now().roundToMinutes()) - 100;
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
    _initPageCount();
    _dragEventStarted = false;
    _verticalScrollController = ScrollController(initialScrollOffset: _currentTimeScrollOffset);
    _pageController = PageController(initialPage: _todayPage);
    _visibleDates = _getVisibleDateForPage(_todayPage);
  }

  @override
  void didUpdateWidget(ScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.daysPerPage != widget.daysPerPage) {
      _jumpToDate(_visibleDates.first);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _verticalScrollController.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dragPositionProvider = Provider.of<EventDragPosition>(context, listen: false);
    return LayoutBuilder(
      builder: (layoutBuilderContext, constraints) {
        final parentSize = Size(constraints.maxWidth, constraints.maxHeight);
        final dayColumnWidth = (parentSize.width - HOUR_ROW_LABEL_LEFT_MARGIN) / widget.daysPerPage;

        return SingleChildScrollView(
          controller: _verticalScrollController,
          child: Listener(
            onPointerMove: (event) {
              if (!_dragEventStarted) {
                return;
              }
              dragPositionProvider.updatePointerYPositionInStack(event.localPosition.dy);
            },
            child: Container(
              width: double.infinity,
              height: _pageHeight + 17, // 17 because extra hour row at bottom for 00:00
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
                    left: HOUR_ROW_LABEL_LEFT_MARGIN,
                    child: _buildPageView(dayColumnWidth),
                  ),
                  _buildCurrentTimeIndicator(),
                  if (_dragEventStarted) _buildDragTargetHourIndicator(Colors.teal),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<DateTime> _getVisibleDateForPage(int pageIndex) {
    return List<DateTime>.generate(widget.daysPerPage, (i) {
      return widget.startDate.add(Duration(days: (pageIndex * widget.daysPerPage) + i));
    });
  }

  void _jumpToDate(DateTime date) {
    int daysToSelectedDate = widget.startDate.difference(date).inDays.abs();
    final newPageIndex = (daysToSelectedDate / widget.daysPerPage).round();
    _pageController.jumpToPage(newPageIndex);
    _updateVisibleDateForPage(newPageIndex);
  }

  void _updateVisibleDateForPage(int pageIndex) {
    setState(() {
      _visibleDates = _getVisibleDateForPage(pageIndex);
    });
  }

  PageView _buildPageView(double dayColumnWidth) {
    return PageView.builder(
      onPageChanged: _updateVisibleDateForPage,
      controller: _pageController,
      itemCount: _pageCount,
      itemBuilder: (pageViewContext, pageIndex) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildPageContent(pageIndex, dayColumnWidth),
        );
      },
    );
  }

  List<Widget> _buildPageContent(int pageIndex, double dayColumnWidth) {
    final visibleDates = _getVisibleDateForPage(pageIndex);
    return visibleDates.map((date) => _buildDayView(date, dayColumnWidth)).toList();
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
      top: _getYOffsetFromTimeInMinutes(now.roundToMinutes()),
      left: 16,
      right: 0,
      child: CurrentTimeIndicator(
        date: now,
      ),
    );
  }

  Widget _buildDragTargetHourIndicator(Color color) {
    return Consumer<EventDragPosition>(
      builder: (context, dragPosition, _) {
        final targetDateTime = _getTimeFromYOffsetForDate(DateTime.now(), dragPosition.eventYPositionInStack);
        return Positioned(
          top: dragPosition.eventYPositionInStack - BASE_TOP_OFFSET,
          left: 0,
          right: 0,
          child: Container(
            child: HourRow(
              hourLabel: DateFormat.Hm().format(targetDateTime),
              showHourLabel: true,
              color: color,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDragTarget(DateTime date, double width) {
    return List<Widget>.generate(_numberOfDragTarget, (index) {
      final targetDateTime = _getTimeFromYOffsetForDate(date, index * _minEventCellHeight + 8);
      return Container(
        height: _minEventCellHeight,
        width: width,
        child: DragTarget<Event>(
          builder: (context, candidates, rejects) {
            return null;
          },
          onAccept: (event) {
            widget.onEventDragCompleted(event.id, targetDateTime);
          },
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

  double _getYOffsetFromTimeInMinutes(int timeInMinutes) {
    return (timeInMinutes * this._pageHeight) / MINUTES_PER_DAY;
  }

  bool _shouldShowRowHour(DateTime date) {
    double safeAreaHeight = _minEventCellHeight;
    int minutesBetweenNow = date.difference(DateTime.now()).inMinutes.abs();
    double difference = minutesBetweenNow * _oneMinuteHeight;
    return difference > safeAreaHeight;
  }

  DateTime _getTimeFromYOffsetForDate(DateTime date, double offset) {
    double totalMinutes = ((offset * MINUTES_PER_DAY) / _pageHeight);
    int hour = (totalMinutes / MINUTES_PER_HOUR).truncate();
    int minutes =
        ((totalMinutes % MINUTES_PER_HOUR) - ((totalMinutes % MINUTES_PER_HOUR) % _minutesPerSection)).truncate();
    return DateTime(date.year, date.month, date.day, hour, minutes, 0);
  }

  List<Positioned> _buildPositionedEvents(DateTime date, double rowWidth) {
    EventDragPosition dragPositionProvider = Provider.of<EventDragPosition>(context, listen: false);

    return _layoutEventsForDate(date, rowWidth).map((eventCell) {
      double topOffset = BASE_TOP_OFFSET + 1;

      final isSameDay = _isSameDay(date, eventCell.event.startDate);

      if (isSameDay) {
        topOffset += _getYOffsetFromTimeInMinutes(eventCell.event.startDate.roundToMinutes());
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
        dragEndHandler: () {
          dragPositionProvider.reset();
          _onDragEventEnd();
        },
        onUpdatePointerYPosition: (localYOffset) {
          dragPositionProvider.updatePointerYPositionInEvent(localYOffset);
        },
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

  // Layout algorithm.
  // Source : https://stackoverflow.com/questions/11311410/visualization-of-calendar-events-algorithm-to-layout-events-with-maximum-width?answertab=active#tab-top

  List<EventCell> _layoutEventsForDate(DateTime date, double rowWidth) {
    List<EventCell> eventCells = [];
    List<List<Event>> eventColumns = [];
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
        eventCells.addAll(_generateEventCells(eventColumns, rowWidth));
        eventColumns = [];
        lastEventEnding = null;
      }

      bool placed = false;

      for (var i = 0; i < eventColumns.length; i++) {
        List<Event> column = eventColumns[i];

        if (!_isOverlaping(column.last, event)) {
          column.add(event);
          placed = true;
          break;
        }
      }

      if (!placed) {
        eventColumns.add([event]);
      }

      if (lastEventEnding == null || event.endDate.isAfter(lastEventEnding)) {
        lastEventEnding = event.endDate;
      }
    });

    if (eventColumns.isNotEmpty) {
      eventCells.addAll(_generateEventCells(eventColumns, rowWidth));
    }

    return eventCells;
  }

  List<EventCell> _generateEventCells(List<List<Event>> columns, double rowWidth) {
    List<EventCell> eventCells = [];

    int columnCount = columns.length;

    for (var i = 0; i < columnCount; i++) {
      List<Event> column = columns[i];

      for (var j = 0; j < column.length; j++) {
        Event event = column[j];

        final colSpan = _calculateEventColSpan(event, i, columns);
        final leftOffsetPercent = (i / columnCount) * 100;

        eventCells.add(
          EventCell(
            event: event,
            top: _getYOffsetFromTimeInMinutes(event.startDate.roundToMinutes()),
            left: (leftOffsetPercent * rowWidth) / 100,
            height: _durationToHeight(event.durationInMinutes),
            width: rowWidth * colSpan / columnCount - 1,
          ),
        );
      }
    }

    return eventCells;
  }

  bool _isOverlaping(Event event1, Event event2) {
    return event1.endDate.isAfter(event2.startDate) && event1.startDate.isBefore(event2.endDate);
  }

  int _calculateEventColSpan(Event event1, int columnIndex, List<List<Event>> columns) {
    int colSpan = 1;

    for (var i = columnIndex + 1; i < columns.length; i++) {
      List<Event> column = columns[i];

      for (var j = 0; j < column.length; j++) {
        Event event2 = column[j];

        if (_isOverlaping(event1, event2)) {
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

class EventDragPosition with ChangeNotifier {
  double _pointerYPositionInEvent = 0;
  double _pointerYPositionInStack = 0;

  double get eventYPositionInStack => _pointerYPositionInStack - _pointerYPositionInEvent;

  void updatePointerYPositionInStack(double newY) {
    _pointerYPositionInStack = newY;
    notifyListeners();
  }

  void updatePointerYPositionInEvent(double newY) {
    _pointerYPositionInEvent = newY;
    notifyListeners();
  }

  void reset() {
    _pointerYPositionInEvent = 0;
    _pointerYPositionInStack = 0;
    notifyListeners();
  }
}
