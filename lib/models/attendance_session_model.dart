class AttendanceSessionModel {
  final String id;
  final String courseCode; // was courseId
  final String createdBy;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String password;
  final String passwordExpiresAt;
  final int passwordRefreshSeconds;
  final int lateAfterMinutes;
  final bool isActive;

  AttendanceSessionModel({
    required this.id,
    required this.courseCode,
    required this.createdBy,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.password,
    required this.passwordExpiresAt,
    required this.passwordRefreshSeconds,
    required this.lateAfterMinutes,
    required this.isActive,
  });

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSessionModel(
      id: json['id']?.toString() ?? '',
      courseCode: json['courseCode']?.toString() ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      passwordExpiresAt: json['passwordExpiresAt']?.toString() ?? '',
      passwordRefreshSeconds: json['passwordRefreshSeconds'] is int
          ? json['passwordRefreshSeconds']
          : int.tryParse(json['passwordRefreshSeconds']?.toString() ?? '') ??
                60,
      lateAfterMinutes: json['lateAfterMinutes'] is int
          ? json['lateAfterMinutes']
          : int.tryParse(json['lateAfterMinutes']?.toString() ?? '') ?? 15,
      isActive: json['isActive'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseCode': courseCode,
      'createdBy': createdBy,
      'title': title,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'password': password,
      'passwordExpiresAt': passwordExpiresAt,
      'passwordRefreshSeconds': passwordRefreshSeconds,
      'lateAfterMinutes': lateAfterMinutes,
      'isActive': isActive,
    };
  }
}
