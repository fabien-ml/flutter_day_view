import 'dart:math';

import 'package:flutter/material.dart';

import './models/event.dart';
import 'day_view.dart';

class HomePage extends StatelessWidget {
  DateTime todayAt(int hour, int min) {
    var today = DateTime.now();
    return DateTime(today.year, today.month, today.day, hour, min, 0);
  }

  @override
  Widget build(BuildContext context) {
    List<Event> events = [];

    events.addAll([
      Event("0", todayAt(0, 0), todayAt(1, 0), false, "Event 0"),
      Event("1", todayAt(8, 0), todayAt(18, 0), false, "Event 1"),
      Event("2", todayAt(8, 0), todayAt(12, 0), false, "Event 2"),
      Event("3", todayAt(9, 30), todayAt(11, 30), false, "Event 3"),
      Event("4", todayAt(12, 00), todayAt(13, 30), false, "Event 4"),
      Event("5", todayAt(15, 30), todayAt(17, 0), false, "Event 5"),
      Event("6", todayAt(17, 0), todayAt(18, 0), false, "Event 6"),
    ]);
/*
    var date = todayAt(0, 0);

    for (var i = 0; i < 96; i++) {
      events.add(
        Event(
          "${i + 7}",
          date,
          date.add(Duration(minutes: 15)),
          false,
          "Event ${i + 7}",
        ),
      );

      date = date.add(Duration(minutes: 15));
    }
*/
    return Scaffold(
      appBar: AppBar(
        title: Text("flutter_day_view"),
      ),
      body: SafeArea(
        child: DayView(
          selectedDate: DateTime.now(),//.add(Duration( days: 1)),
          events: events,
        ),
      ),
    );
  }
}
