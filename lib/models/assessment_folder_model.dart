import 'dart:convert';

class AssessmentFolderModel {
  final String id;
  final String name;
  final String colorHex;
  final List<String> assessmentKeys; // "courseCode|assessmentName"
  final int order;

  AssessmentFolderModel({
    required this.id,
    required this.name,
    required this.colorHex,
    List<String>? assessmentKeys,
    this.order = 0,
  }) : assessmentKeys = assessmentKeys ?? [];

  /// Check if a specific assessment belongs to this folder.
  bool containsAssessment(String courseCode, String assessmentName) {
    return assessmentKeys.contains('$courseCode|$assessmentName');
  }

  /// Create a copy with modifications.
  AssessmentFolderModel copyWith({
    String? name,
    String? colorHex,
    List<String>? assessmentKeys,
    int? order,
  }) {
    return AssessmentFolderModel(
      id: id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      assessmentKeys: assessmentKeys ?? List.from(this.assessmentKeys),
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'assessmentKeys': assessmentKeys,
        'order': order,
      };

  factory AssessmentFolderModel.fromJson(Map<String, dynamic> json) {
    return AssessmentFolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String,
      assessmentKeys: (json['assessmentKeys'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      order: json['order'] as int? ?? 0,
    );
  }

  /// Encode a list of folders for SharedPreferences storage.
  static String encodeList(List<AssessmentFolderModel> folders) {
    return jsonEncode(folders.map((f) => f.toJson()).toList());
  }

  /// Decode a list of folders from SharedPreferences storage.
  static List<AssessmentFolderModel> decodeList(String jsonString) {
    final list = jsonDecode(jsonString) as List<dynamic>;
    return list
        .map((e) => AssessmentFolderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
