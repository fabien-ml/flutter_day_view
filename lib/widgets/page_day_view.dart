import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import './day_view.dart';
import '../models/event.dart';

class PageDayView extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<Event> events;
  final int daysPerPage;
  final Function(DateTime) onReachStartDate;
  final Function(DateTime) onReachEndDate;
  final Function(String eventId, DateTime targetStartDate) onEventDragCompleted;

  PageDayView({
    @required this.startDate,
    @required this.endDate,
    @required this.events,
    @required this.onReachStartDate,
    @required this.onReachEndDate,
    @required this.daysPerPage,
    @required this.onEventDragCompleted,
  });

  @override
  _PageDayViewState createState() => _PageDayViewState();
}

class _PageDayViewState extends State<PageDayView> {
  PageController _pageController;
  int _numberOfPages;
  bool _isChangingPage;

  @override
  void initState() {
    super.initState();
    _isChangingPage = false;
    _numberOfPages = (widget.startDate.difference(widget.endDate).inDays.abs() / widget.daysPerPage).round();
    final pageOfToday = (widget.startDate.difference(DateTime.now()).inDays.abs() / widget.daysPerPage).round();
    _pageController = PageController(initialPage: pageOfToday);
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentSize = Size(constraints.maxWidth, constraints.maxHeight);
        final columnWidth  = parentSize.width / widget.daysPerPage;

        final triggerAreaWidth = 30;

        return Listener(

          onPointerMove: (event) {
            final currentLocalXPosition = event.localPosition.dx;

            if (_isChangingPage) {
              return;
            }

            if (currentLocalXPosition < triggerAreaWidth && _pageController.page > 0) {
              _goToPreviousPage();
            } else if (currentLocalXPosition > parentSize.width - triggerAreaWidth && _pageController.page < _numberOfPages - 1) {
              _goToNextPage();
            }
          },
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (pageIndex) {
              if (pageIndex == 0) {
                widget.onReachStartDate(widget.startDate);
              } else if (pageIndex == _numberOfPages - 1) {
                widget.onReachEndDate(widget.endDate);
              }
            },
            itemCount: _numberOfPages,
            itemBuilder: (context, pageIndex) {
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List<Widget>.generate(widget.daysPerPage, (columnIndex) {
                    final date = widget.startDate.add(Duration(days: (pageIndex * widget.daysPerPage) + columnIndex));
                    return _buildColumn(date, columnWidth);
                  })
              );
            },
          ),
        );
      },
    );
  }

  void _updateIsChangingPage(bool newValue) {
    setState(() {
      _isChangingPage = newValue;
    });
  }

  void _goToPreviousPage() {
    _updateIsChangingPage(true);
    _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    //_updateIsChangingPage(false);
  }

  void _goToNextPage() {
    _updateIsChangingPage(true);
    _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    //_updateIsChangingPage(false);
  }

  Widget _buildColumn(DateTime date, double width) {
    return Container(
      width: width,
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                DateFormat.yMMMMEEEEd().format(date),
                style: TextStyle(
                    color: Colors.blue
                ),
              ),
            ),
          ),
          Expanded(
            child: DayView(
              date: date,
              events: _getEventInDate(date),
              onEventDragCompleted: widget.onEventDragCompleted,
            ),
          ),
        ],
      ),
    );
  }

  List<Event> _getEventInDate(DateTime date) {
    return widget.events.where((event) => _isSameDay(event.startDate, date) || _isSameDay(event.endDate, date)).toList();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
