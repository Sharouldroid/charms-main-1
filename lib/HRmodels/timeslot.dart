class TimeSlot {
  final String startTime;
  final String endTime;
  final List<String> breaks;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.breaks,
  });
}