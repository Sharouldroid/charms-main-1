class WorkingPeriod {
  final String startTime;
  final String endTime;

  WorkingPeriod({
    required this.startTime,
    required this.endTime,
  });

  factory WorkingPeriod.fromJson(Map<String, dynamic> json) {
    return WorkingPeriod(
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