import 'package:flutter/material.dart';

import 'day_view.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("flutter_day_view"),),
      body: SafeArea(
        child: DayView(),
      ),
    );
  }
}

