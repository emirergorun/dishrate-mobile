enum ClaimStatus { pending, approved, rejected, unknown }

/// Bir restoranın sahipliği için açılmış talep.
///
/// Önceki "başvuru" modelinin yerini aldı: restoran zaten katalogda kayıtlı
/// olduğu için talep yalnızca "hangi kullanıcı, hangi restoran" bilgisini
/// taşır — adres ve iletişim alanları yok.
class RestaurantClaimModel {
  final int id;

  final int userId;
  final String? username;

  final int restaurantId;
  final String restaurantName;
  final String? restaurantAddress;

  final ClaimStatus status;
  final String? adminNote;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const RestaurantClaimModel({
    required this.id,
    required this.userId,
    this.username,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantAddress,
    required this.status,
    this.adminNote,
    this.createdAt,
    this.reviewedAt,
  });

  bool get isPending => status == ClaimStatus.pending;
  bool get isApproved => status == ClaimStatus.approved;
  bool get isRejected => status == ClaimStatus.rejected;

  static ClaimStatus _parseStatus(String? raw) => switch (raw) {
        'PENDING' => ClaimStatus.pending,
        'APPROVED' => ClaimStatus.approved,
        'REJECTED' => ClaimStatus.rejected,
        _ => ClaimStatus.unknown,
      };

  factory RestaurantClaimModel.fromJson(Map<String, dynamic> json) {
    return RestaurantClaimModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      username: json['username'] as String?,
      restaurantId: json['restaurantId'] as int,
      restaurantName: json['restaurantName'] as String? ?? '',
      restaurantAddress: json['restaurantAddress'] as String?,
      status: _parseStatus(json['status'] as String?),
      adminNote: json['adminNote'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
    );
  }
}
