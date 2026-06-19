class AssessmentModel {
  final String assessmentName;
  final String courseCode;
  final String? guide;
  final String? icon;
  final String? color;
  final String? imageBase64;
  final String? createdBy;
  final String? createdAt;

  AssessmentModel({
    required this.assessmentName,
    required this.courseCode,
    this.guide,
    this.icon,
    this.color,
    this.imageBase64,
    this.createdAt,
    this.createdBy,
  });

  factory AssessmentModel.fromMap(Map<String, dynamic> map) {
    return AssessmentModel(
      assessmentName: map['assessmentName']?.toString() ?? '',
      courseCode: map['courseCode']?.toString() ?? '',
      guide: map['guide']?.toString(),
      icon: map['icon']?.toString(),
      color: map['color']?.toString(),
      imageBase64: map['imageBase64']?.toString(),
      createdAt: map['createdAt']?.toString(),
      createdBy: map['createdBy']?.toString(),
    );
  }
}
