class AssessmentModel {
  final String assessmentName;
  final String courseCode;
  final String? createdBy;
  final String? createdAt;

  AssessmentModel({
    required this.assessmentName,
    required this.courseCode,
    this.createdAt,
    this.createdBy,
  });

  factory AssessmentModel.fromMap(Map<String, dynamic> map) {
    return AssessmentModel(
      assessmentName: map['assessmentName'],
      courseCode: map['courseCode'],
      createdAt: map['createdAt'],
      createdBy: map['createdBy'],
    );
  }
}
