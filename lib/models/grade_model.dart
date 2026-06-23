class GradeModel {
  final String studentId;
  final String studentName;
  final String courseCode;
  final String assessmentName;
  final double score;
  final double maxScore;
  final String? gradedBy;
  final String? gradedAt;

  GradeModel({
    required this.studentId,
    required this.studentName,
    required this.courseCode,
    required this.assessmentName,
    required this.score,
    required this.maxScore,
    this.gradedBy,
    this.gradedAt,
  });

  factory GradeModel.fromMap(Map<String, dynamic> map) {
    return GradeModel(
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      courseCode: map['courseCode']?.toString() ?? '',
      assessmentName: map['assessmentName']?.toString() ?? '',
      score: double.tryParse(map['score']?.toString() ?? '') ?? 0,
      maxScore: double.tryParse(map['maxScore']?.toString() ?? '') ?? 100,
      gradedBy: map['gradedBy']?.toString(),
      gradedAt: map['gradedAt']?.toString(),
    );
  }
}
