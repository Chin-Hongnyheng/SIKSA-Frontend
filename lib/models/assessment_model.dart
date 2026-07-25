class AssessmentModel {
  final String assessmentName;
  final String courseCode;
  final String? guide;
  final String? icon;
  final String? color;
  final String? imageBase64;
  final bool isHidden;
  final String createdBy;
  final DateTime createdAt;

  AssessmentModel({
    required this.assessmentName,
    required this.courseCode,
    this.guide,
    this.icon,
    this.color,
    this.imageBase64,
    this.isHidden = false,
    required this.createdBy,
    required this.createdAt,
  });

  factory AssessmentModel.fromMap(Map<String, dynamic> map) {
    return AssessmentModel(
      assessmentName: map['assessmentName'] ?? '',
      courseCode: map['courseCode'] ?? '',
      guide: map['guide'],
      icon: map['icon'],
      color: map['color'],
      imageBase64: map['imageBase64'],
      isHidden: map['isHidden'] ?? false,
      createdBy: map['createdBy'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assessmentName': assessmentName,
      'courseCode': courseCode,
      'guide': guide,
      'icon': icon,
      'color': color,
      'imageBase64': imageBase64,
      'isHidden': isHidden,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
