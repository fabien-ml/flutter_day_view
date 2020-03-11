import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrentTimeIndicator extends StatelessWidget {
  final DateTime date;
  final Color color;

  CurrentTimeIndicator({
    @required this.date,
    this.color = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            DateFormat.Hm().format(this.date),
            style: TextStyle(
              color: this.color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _LineIndicator(this.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineIndicator extends StatelessWidget {
  final Color color;

  _LineIndicator(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Stack(
        children: <Widget>[
          Positioned(
            height: 1,
            top: 3,
            left: 0,
            right: 0,
            child: Divider(
              color: this.color,
              thickness: 1,
            ),
          ),
          Container(
            height: 7,
            width: 7,
            margin: EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: this.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
