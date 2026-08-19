class NotificationModel {
  final int id;
  final String type; // NEW_RATING
  final String title;
  final String body;
  final int? menuItemId;
  final String? menuItemName;
  final bool read;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.menuItemId,
    this.menuItemName,
    required this.read,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      menuItemId: json['menuItemId'] as int?,
      menuItemName: json['menuItemName'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
