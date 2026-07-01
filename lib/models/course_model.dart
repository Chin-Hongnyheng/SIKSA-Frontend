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
  });

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    final rawSubscribers = map['subscribers'];

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
      subscribers: rawSubscribers is List
          ? rawSubscribers
                .map(
                  (subscriber) => CourseSubscriberModel.fromMap(
                    Map<String, dynamic>.from(subscriber as Map),
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
    );
  }
}
