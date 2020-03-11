class Event {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final bool allDay;
  final String title;

  const Event(this.id, this.startDate, this.endDate, this.allDay, this.title);

  int get durationInMinutes {
    return startDate.difference(endDate).inMinutes.abs();
  }

  Event copyWith({String id, DateTime startDate, DateTime endDate, bool allDay, String title}) {
    return Event(
      id ?? this.id,
      startDate ?? this.startDate,
      endDate ?? this.endDate,
      allDay ?? this.allDay,
      title ?? this.title,
    );
  }
}