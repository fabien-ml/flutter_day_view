import 'package:flutter/material.dart';
import 'package:flutterdayview/DayView.dart';

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

