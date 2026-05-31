class UserModel {
  final int userId;
  final String username;
  final String email;
  final String? profilePhotoUrl;
  final String? bio;

  const UserModel({
    required this.userId,
    required this.username,
    required this.email,
    this.profilePhotoUrl,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      bio: json['bio'] as String?,
    );
  }
}
