class ScheduleViewEvent {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final bool allDay;
  final String title;

  const ScheduleViewEvent(this.id, this.startDate, this.endDate, this.allDay, this.title);

  int get durationInMinutes {
    return startDate.difference(endDate).inMinutes.abs();
  }

  ScheduleViewEvent copyWith({String id, DateTime startDate, DateTime endDate, bool allDay, String title}) {
    return ScheduleViewEvent(
      id ?? this.id,
      startDate ?? this.startDate,
      endDate ?? this.endDate,
      allDay ?? this.allDay,
      title ?? this.title,
    );
  }
}