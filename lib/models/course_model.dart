class CourseSubscriberModel {
  final String id;
  final String userName;
  final String email;

  CourseSubscriberModel({
    required this.id,
    required this.userName,
    required this.email,
  });

  factory CourseSubscriberModel.fromMap(Map<String, dynamic> map) {
    return CourseSubscriberModel(
      id: map['id']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
    );
  }
}

class CourseMaterialModel {
  final String name;
  final String url;
  final String uploadedAt;

  CourseMaterialModel({
    required this.name,
    required this.url,
    required this.uploadedAt,
  });

  factory CourseMaterialModel.fromMap(Map<String, dynamic> map) {
    return CourseMaterialModel(
      name: map['name']?.toString() ?? 'Document',
      url: map['url']?.toString() ?? '',
      uploadedAt: map['uploaded_at']?.toString() ?? '',
    );
  }
}

class CourseModel {
  final String courseName;
  final String courseCode;
  final String? description;
  final String? createdBy;
  final String? createdAt;
  final int subscriberCount;
  final bool isSubscribed;
  final List<CourseSubscriberModel> subscribers;
  final String? courseImg;
  final String? colorHex;
  final List<CourseMaterialModel> materials;

  CourseModel({
    required this.courseCode,
    required this.courseName,
    this.description,
    this.createdBy,
    this.createdAt,
    this.subscriberCount = 0,
    this.isSubscribed = false,
    this.subscribers = const [],
    this.courseImg,
    this.colorHex,
    this.materials = const [],
  });

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    final rawSubscribers = map['subscribers'];
    final rawMaterials = map['materials'];

    return CourseModel(
      courseCode: map['courseCode']?.toString() ?? '',
      courseName: map['courseName']?.toString() ?? '',
      description: map['description']?.toString(),
      createdBy: map['createdBy']?.toString(),
      createdAt: map['createdAt']?.toString(),
      subscriberCount:
          int.tryParse(map['subscriberCount']?.toString() ?? '') ?? 0,
      isSubscribed: map['isSubscribed'] == true,
      courseImg: map['courseImg']?.toString(),
      colorHex: map['colorHex']?.toString(),
      subscribers: rawSubscribers is List
          ? rawSubscribers
                .map(
                  (subscriber) => CourseSubscriberModel.fromMap(
                    Map<String, dynamic>.from(subscriber as Map),
                  ),
                )
                .toList()
          : const [],
      materials: rawMaterials is List
          ? rawMaterials
                .map(
                  (m) => CourseMaterialModel.fromMap(
                    Map<String, dynamic>.from(m as Map),
                  ),
                )
                .toList()
          : const [],
    );
  }

  CourseModel copyWith({
    String? courseCode,
    String? courseName,
    String? description,
    String? createdBy,
    String? createdAt,
    int? subscriberCount,
    bool? isSubscribed,
    List<CourseSubscriberModel>? subscribers,
    String? courseImg,
    String? colorHex,
    List<CourseMaterialModel>? materials,
  }) {
    return CourseModel(
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      subscribers: subscribers ?? this.subscribers,
      courseImg: courseImg ?? this.courseImg,
      colorHex: colorHex ?? this.colorHex,
      materials: materials ?? this.materials,
    );
  }
}
