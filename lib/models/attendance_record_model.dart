class AttendanceRecordModel {
  final String id;
  final String studentId;
  final String courseId;
  final String sessionId;
  final String date;
  final String status;
  final String? checkIn;
  final String? checkOut;
  final String? type;
  final String? time;

  AttendanceRecordModel({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.sessionId,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.type,
    this.time,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      courseId: json['courseId']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      checkIn: json['checkIn']?.toString(),
      checkOut: json['checkOut']?.toString(),
      type: json['type']?.toString(),
      time: json['time']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'courseId': courseId,
      'sessionId': sessionId,
      'date': date,
      'status': status,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'type': type,
      'time': time,
    };
  }
}