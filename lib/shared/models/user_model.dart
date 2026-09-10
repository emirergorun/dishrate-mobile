enum UserRole { user, restaurantOwner, admin }

class UserModel {
  final int userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String email;
  /// Kırpılmış, ekranda gösterilen hâli.
  final String? profilePhotoUrl;

  /// Kırpılmamış özgün yükleme. Fotoğrafı yeniden çerçevelerken galeriden
  /// tekrar seçmeye gerek kalmasın diye saklanır.
  final String? profilePhotoOriginalUrl;

  /// Özgün görsel üzerindeki kırpma dikdörtgeni: "x,y,genişlik,yükseklik".
  final String? profilePhotoCrop;

  final String? bio;
  final UserRole role;

  /// İsim/soyisim'in tekrar değiştirilebileceği en erken zaman.
  /// null → şu an değiştirilebilir.
  final DateTime? nameChangeAvailableAt;

  const UserModel({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    required this.email,
    this.profilePhotoUrl,
    this.profilePhotoOriginalUrl,
    this.profilePhotoCrop,
    this.bio,
    this.role = UserRole.user,
    this.nameChangeAvailableAt,
  });

  /// Yeniden çerçevelenebilecek bir özgün görsel var mı?
  /// (Eski kayıtlarda yalnızca kırpılmış hâli olabilir.)
  bool get canRecropPhoto =>
      profilePhotoOriginalUrl != null &&
      profilePhotoOriginalUrl!.trim().isNotEmpty;

  /// İsim/soyisim şu an değiştirilebilir mi? (15 günlük pencere dolmuş mu)
  bool get canChangeName =>
      nameChangeAvailableAt == null ||
      DateTime.now().isAfter(nameChangeAvailableAt!);

  /// "İsim Soyisim" — ikisi de yoksa username'e düşer.
  String get fullName {
    final parts = [firstName, lastName]
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim());
    final joined = parts.join(' ');
    return joined.isEmpty ? username : joined;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as int,
      username: json['username'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String,
      // Fotoğraf kaldırıldığında sunucuya boş metin gidiyor. Boşu null'a
      // çevirmezsek `profilePhotoUrl != null` kontrolleri doğru kalır ve
      // kaldırılan fotoğrafın yerinde kırık görsel görünür.
      profilePhotoUrl: _bosuNull(json['profilePhotoUrl'] as String?),
      profilePhotoOriginalUrl:
          _bosuNull(json['profilePhotoOriginalUrl'] as String?),
      profilePhotoCrop: _bosuNull(json['profilePhotoCrop'] as String?),
      bio: json['bio'] as String?,
      role: _parseRole(json['role'] as String?),
      nameChangeAvailableAt: json['nameChangeAvailableAt'] != null
          ? DateTime.tryParse(json['nameChangeAvailableAt'] as String)
          : null,
    );
  }

  static String? _bosuNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static UserRole _parseRole(String? raw) {
    return switch (raw) {
      'RESTAURANT_OWNER' => UserRole.restaurantOwner,
      'ADMIN'            => UserRole.admin,
      _                  => UserRole.user,
    };
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isRestaurantOwner => role == UserRole.restaurantOwner;
  bool get isUser => role == UserRole.user;
}
