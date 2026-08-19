enum ApplicationStatus { pending, approved, rejected, unknown }

class RestaurantApplicationModel {
  final int id;
  final String restaurantName;
  final String city;
  final String? district;
  final ApplicationStatus status;
  final String type; // "NEW_RESTAURANT" | "CLAIM"
  final String? adminNote;
  final int? linkedRestaurantId;
  final String? applicantUsername;
  final String? applicantEmail;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const RestaurantApplicationModel({
    required this.id,
    required this.restaurantName,
    required this.city,
    this.district,
    required this.status,
    required this.type,
    this.adminNote,
    this.linkedRestaurantId,
    this.applicantUsername,
    this.applicantEmail,
    this.createdAt,
    this.reviewedAt,
  });

  bool get isPending => status == ApplicationStatus.pending;
  bool get isApproved => status == ApplicationStatus.approved;
  bool get isRejected => status == ApplicationStatus.rejected;

  static ApplicationStatus _parseStatus(String? raw) {
    return switch (raw) {
      'PENDING' => ApplicationStatus.pending,
      'APPROVED' => ApplicationStatus.approved,
      'REJECTED' => ApplicationStatus.rejected,
      _ => ApplicationStatus.unknown,
    };
  }

  factory RestaurantApplicationModel.fromJson(Map<String, dynamic> json) {
    return RestaurantApplicationModel(
      id: json['id'] as int,
      restaurantName: json['restaurantName'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String?,
      status: _parseStatus(json['status'] as String?),
      type: json['type'] as String? ?? 'NEW_RESTAURANT',
      adminNote: json['adminNote'] as String?,
      linkedRestaurantId: json['linkedRestaurantId'] as int?,
      applicantUsername: json['applicantUsername'] as String?,
      applicantEmail: json['applicantEmail'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'].toString())
          : null,
    );
  }
}
