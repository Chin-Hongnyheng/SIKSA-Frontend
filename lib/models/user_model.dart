class UserModel {
  final String id;
  final String userName;
  final String email;
  final int? phone;
  final String role;
  final String? dob;
  final String? gender;
  final String? address;
  final String? photoUrl;
  final String notification;
  final String language;

  UserModel({
    required this.id,
    required this.userName,
    required this.email,
    this.phone,
    required this.role,
    this.dob,
    this.gender,
    this.address,
    this.photoUrl,
    required this.notification,
    required this.language,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone'] is int
          ? map['phone']
          : int.tryParse(
              map['phone']?.toString() ?? '',
            ), // 👈 handle int safely
      role: map['role']?.toString() ?? '',
      dob: map['dob']?.toString(),
      gender: map['gender']?.toString(),
      address: map['address']?.toString(),
      photoUrl: map['photo_url']?.toString(),
      notification: map['notification']?.toString() ?? 'ON',
      language: map['language']?.toString() ?? 'ENGLISH',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userName': userName,
      'email': email,
      'phone': phone != null ? '+$phone' : null,
      'role': role,
      'dob': dob,
      'gender': gender,
      'address': address,
      'photo_url': photoUrl,
      'notification': notification,
      'language': language,
    };
  }
}
