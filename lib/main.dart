import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models/schedule_view_event.dart';
import 'widgets/schedule_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Day View',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ScheduleViewEvent> _events = [];
  int _daysPerPage = 1;

  @override
  void initState() {
    super.initState();
    _generateFakeEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("flutter_day_view"),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Container(
              height: 44,
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: RaisedButton(
                      child: Text("1"),
                      color: Colors.amber,
                      onPressed: () {
                        setState(() {
                          _daysPerPage = 1;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RaisedButton(
                      color: Colors.green,
                      child: Text("5"),
                      onPressed: () {
                        setState(() {
                          _daysPerPage = 5;
                        });
                      },
                    ),
                  )
                ],
              ),
            ),
            Expanded(
              child: ScheduleView(
                daysPerPage: _daysPerPage,
                events: _events,
                startDate: DateTime.now().subtract(Duration(days: 45)),
                endDate: DateTime.now().add(Duration(days: 45)),
                onEventDragCompleted: _updateEvent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FOR TEST PURPOSE

  void _updateEvent(String eventId, DateTime newStartDate) {
    ScheduleViewEvent event = _events.firstWhere((it) => it.id == eventId);

    if (event == null || event.startDate == newStartDate) {
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

  void _generateFakeEvents() {
/*
    final date = DateTime.now().subtract(Duration(days: 21));
    DateTime dateAtStartOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);

    _events.addAll(List<List<ScheduleViewEvent>>.generate(90, (i) {

      List<ScheduleViewEvent> days = [];

      days.addAll(List<ScheduleViewEvent>.generate(96, (j) {

        final startDate = dateAtStartOfDay.add(Duration(minutes: 15));

        final event = ScheduleViewEvent("$i$j", startDate, startDate.add(Duration(minutes: 15)), false, "Event $i$j");

        dateAtStartOfDay = startDate;

        return event;

      }));

      dateAtStartOfDay = DateTime(date.year, date.month, date.day + i, 0, 0, 0);

      return days;

    }).expand((it) => it.toList()));
*/
    _events.addAll([
      ScheduleViewEvent("0", _todayAt(0, 0), _todayAt(1, 0), false, "Event 0"),
      ScheduleViewEvent("1", _todayAt(8, 0), _todayAt(18, 0), false, "Event 1"),
      ScheduleViewEvent("2", _todayAt(8, 30), _todayAt(12, 0), false, "Event 2"),
      ScheduleViewEvent("3", _todayAt(9, 30), _todayAt(11, 30), false, "Event 3"),
      ScheduleViewEvent("4", _todayAt(7, 00), _todayAt(8, 30), false, "Event 4"),
      ScheduleViewEvent("5", _todayAt(15, 30), _todayAt(17, 0), false, "Event 5"),
      ScheduleViewEvent("6", _todayAt(17, 0), _todayAt(18, 0), false, "Event 6"),
    ]);
  }

  DateTime _todayAt(int hour, int min) {
    var today = DateTime.now();
    return DateTime(today.year, today.month, today.day, hour, min, 0);
  }
}
