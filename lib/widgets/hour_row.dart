import 'package:flutter/material.dart';

class HourRow extends StatelessWidget {
  final String hourLabel;
  final bool showHourLabel;
  final Color color;

  HourRow({
    @required this.hourLabel,
    @required this.showHourLabel,
    this.color = Colors.grey
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showHourLabel)
            Text(
              hourLabel,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: showHourLabel ? 4 : 42),
              child: Divider(
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}