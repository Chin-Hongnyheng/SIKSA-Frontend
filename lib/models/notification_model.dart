import 'dart:convert';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isUnread;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.data,
    required this.isUnread,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedData;
    if (json['data'] != null) {
      try {
        parsedData = jsonDecode(json['data']);
      } catch (e) {
        parsedData = null;
      }
    }

    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      data: parsedData,
      isUnread: json['isUnread'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
