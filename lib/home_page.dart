import 'package:flutter/material.dart';
import 'package:flutter_day_view/widgets/page_day_view.dart';

import './models/event.dart';
import 'widgets/day_view.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Event> _allEvents = [];

  @override
  void initState() {
    super.initState();

    /*
    _events.addAll([
      Event("0", todayAt(0, 0), todayAt(1, 0), false, "Event 0"),
      Event("1", todayAt(8, 0), todayAt(18, 0), false, "Event 1"),
      Event("2", todayAt(8, 0), todayAt(12, 0), false, "Event 2"),
      Event("3", todayAt(9, 30), todayAt(11, 30), false, "Event 3"),
      Event("4", todayAt(12, 00), todayAt(13, 30), false, "Event 4"),
      Event("5", todayAt(15, 30), todayAt(17, 0), false, "Event 5"),
      Event("6", todayAt(17, 0), todayAt(18, 0), false, "Event 6"),
      Event("7", todayAt(22, 0), todayAt(22, 0).add(Duration(hours: 5)), false, "Event 7"),
      Event("8", todayAt(1, 0).subtract(Duration(hours: 5)), todayAt(3, 0), false, "Event 8"),
    ]);

    */

    final date = DateTime.now().subtract(Duration(days: 45));
    DateTime dateAtStartOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);

    _allEvents.addAll(List<List<Event>>.generate(90, (i) {

      List<Event> days = [];

      days.addAll(List<Event>.generate(96, (j) {

        final startDate = dateAtStartOfDay.add(Duration(minutes: 15));

        final event = Event("$i$j", startDate, startDate.add(Duration(minutes: 15)), false, "Event $i$j");

        dateAtStartOfDay = startDate;

        return event;

      }));

      dateAtStartOfDay = DateTime(date.year, date.month, date.day + i, 0, 0, 0);

      return days;

    }).expand((it) => it.toList()));

  }

  DateTime todayAt(int hour, int min) {
    var today = DateTime.now();
    return DateTime(today.year, today.month, today.day, hour, min, 0);
  }

  void _updateEvent(String eventId, DateTime newStartDate) {
    Event event = _allEvents.firstWhere((it) => it.id == eventId);

    if (event == null) {
      return;
    }

    if (event.startDate == newStartDate) {
      return;
    }

    final duration = event.endDate.difference(event.startDate);
    final newEndDate = newStartDate.add(duration);
    setState(() {
      _allEvents.removeWhere((it) => it.id == event.id);
      _allEvents.add(event.copyWith(
        startDate: newStartDate,
        endDate: newEndDate,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("flutter_day_view"),
      ),
      body: SafeArea(
        child: PageDayView(
          daysPerPage: 1,
          startDate: DateTime.now().subtract(Duration(days: 45)),
          endDate: DateTime.now().add(Duration(days: 45)),
          events: _allEvents,
          onReachStartDate: (startDate) => print(startDate),
          onReachEndDate: (endDate) => print(endDate),
          onEventDragCompleted: _updateEvent,
        )
      ),
    );
  }
}
