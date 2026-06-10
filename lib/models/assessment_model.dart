class AssessmentModel {
  final String assessmentName;
  final String courseCode;
  final String? guide;
  final String? createdBy;
  final String? createdAt;

  AssessmentModel({
    required this.assessmentName,
    required this.courseCode,
    this.guide,
    this.createdAt,
    this.createdBy,
  });

  factory AssessmentModel.fromMap(Map<String, dynamic> map) {
    return AssessmentModel(
      assessmentName: map['assessmentName']?.toString() ?? '',
      courseCode: map['courseCode']?.toString() ?? '',
      guide: map['guide']?.toString(),
      createdAt: map['createdAt']?.toString(),
      createdBy: map['createdBy']?.toString(),
    );
  }
}
