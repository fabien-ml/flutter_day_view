extension DateTimeExtension on DateTime {
  DateTime floorToNearestMinutesSection(int minutesSection) {
    return this.subtract(Duration(minutes: (this.minute % minutesSection)));
  }

  int roundToMinutes() {
    return (this.hour * 60) + this.minute;
  }
}