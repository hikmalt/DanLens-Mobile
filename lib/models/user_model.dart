// lib/models/user_model.dart
class UserModel {
  final int id;
  final String name;
  final String email;
  final String? role;
  final String? photo;
  final DateTime? createdAt;
 
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.photo,
    this.createdAt,
  });
 
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'],
      photo: json['photo'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
 
  bool get isAdmin => role == 'admin';
 
  String get photoUrl {
    if (photo == null || photo!.isEmpty) return '';
    return 'https://rnafixrgoucrplssoqtm.supabase.co/storage/v1/object/public/profil/$photo';
  }
}