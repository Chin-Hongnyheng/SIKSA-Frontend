class ScheduleModel {
  final String scheduleId;
  final String courseCode;
  final String assessmentName;
  final String location;
  final String startTime;
  final String endTime;
  final String recurrenceType;
  final String? date;
  final String? startDate;
  final String? endDate;
  final String color;
  final int reminder;
  List<String>? selectedDays;

  /// 'own'      = schedule the user created themselves
  /// 'enrolled' = schedule from a course the user enrolled in
  /// null       = unknown (legacy / not yet tagged)
  final String? source;

  ScheduleModel({
    required this.scheduleId,
    required this.courseCode,
    required this.assessmentName,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.recurrenceType,
    this.date,
    this.startDate,
    this.endDate,
    required this.color,
    required this.reminder,
    this.selectedDays,
    this.source,
  });

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      scheduleId: map['scheduleId'] ?? map['_id'] ?? '',
      courseCode: map['courseCode'] ?? '',
      assessmentName: map['assessmentName'] ?? '',
      location: map['location'] ?? '',
      startTime: _parseTime(map['startTime'] ?? map['start_time'] ?? ''),
      endTime: _parseTime(map['endTime'] ?? map['end_time'] ?? ''),
      recurrenceType:
          (map['recurrenceType'] ?? map['recurrence_type'] ?? 'none')
              .toString()
              .toLowerCase(),
      date: map['date'],
      startDate: map['startDate'],
      endDate: map['endDate'],
      color: map['color'] ?? '',
      reminder: map['reminder'] ?? 0,
      selectedDays: (map['selectedDays'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      // source is always set by the provider after fetching, not from the API
      source: null,
    );
  }

  /// Returns a copy of this model with only the specified fields replaced.
  ScheduleModel copyWith({
    String? scheduleId,
    String? courseCode,
    String? assessmentName,
    String? location,
    String? startTime,
    String? endTime,
    String? recurrenceType,
    String? date,
    String? startDate,
    String? endDate,
    String? color,
    int? reminder,
    List<String>? selectedDays,
    String? source,
  }) {
    return ScheduleModel(
      scheduleId: scheduleId ?? this.scheduleId,
      courseCode: courseCode ?? this.courseCode,
      assessmentName: assessmentName ?? this.assessmentName,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      date: date ?? this.date,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      color: color ?? this.color,
      reminder: reminder ?? this.reminder,
      selectedDays: selectedDays ?? this.selectedDays,
      source: source ?? this.source,
    );
  }

  static String _parseTime(String raw) {
    if (raw.isEmpty) return '';
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(raw)) return raw;
    try {
      final dt = DateTime.parse(raw).toUtc();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return raw;
    }
  }
}
