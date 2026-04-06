class BreakPeriod {
  final String startTime;
  final String endTime;

  BreakPeriod({
    required this.startTime,
    required this.endTime,
  });

  factory BreakPeriod.fromJson(Map<String, dynamic> json) {
    return BreakPeriod(
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}