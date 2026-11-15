class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String currency;
  final String timezone;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.currency,
    required this.timezone,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: (json['fullName'] ?? '') as String,
      currency: (json['currency'] ?? 'VND') as String,
      timezone: (json['timezone'] ?? 'Asia/Ho_Chi_Minh') as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'currency': currency,
      'timezone': timezone,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
