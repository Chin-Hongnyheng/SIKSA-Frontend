class AttendanceRecordModel {
  final String id;
  final String studentId;
  final String? courseCode; // was courseId, nullable from backend
  final String? sessionId; // nullable
  final String? date; // nullable
  final String? status; // nullable
  final String? checkIn;
  final String? checkOut;
  final String? type;
  final String? time;

  AttendanceRecordModel({
    required this.id,
    required this.studentId,
    this.courseCode,
    this.sessionId,
    this.date,
    this.status,
    this.checkIn,
    this.checkOut,
    this.type,
    this.time,
  });

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      courseCode: json['courseCode']?.toString(),
      sessionId: json['sessionId']?.toString(),
      date: json['date']?.toString(),
      status: json['status']?.toString(),
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
      'courseCode': courseCode,
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
