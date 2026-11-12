import 'package:ehsan_pathways/core/json_read.dart';
/// Represents the authenticated user returned by the API.
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (jInt(json['id']) ?? 0),
      name: (jStr(json['name']) ?? ''),
      email: (jStr(json['email']) ?? ''),
      avatar: jStr(json['avatar']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse((jStr(json['created_at']) ?? ''))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar': avatar,
        'created_at': createdAt?.toIso8601String(),
      };

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
