import 'package:flutter/material.dart';

import 'day_view.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DayView()
      ),
    );
  }
}

