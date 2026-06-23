import 'dart:convert';

class AssessmentFolderModel {
  final String id;
  final String name;
  final String colorHex;
  final List<String> assessmentKeys; // "courseCode|assessmentName"

  AssessmentFolderModel({
    required this.id,
    required this.name,
    required this.colorHex,
    List<String>? assessmentKeys,
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
  }) {
    return AssessmentFolderModel(
      id: id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      assessmentKeys: assessmentKeys ?? List.from(this.assessmentKeys),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
        'assessmentKeys': assessmentKeys,
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
