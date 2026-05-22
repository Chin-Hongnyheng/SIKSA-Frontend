class CourseModel {
  final String courseName;
  final String courseCode;
  final String? description;
  final String? createdBy;
  final String? createdAt;

  CourseModel({
    required this.courseCode,
    required this.courseName,
    this.description,
    this.createdBy,
    this.createdAt,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      courseCode: map['courseCode'],
      courseName: map['courseName'],
      description: map['description'],
      createdBy: map['createdBy'],
      createdAt: map['createdAt'],
    );
  }
}
