class PaymentMethodModel {
  final String id;
  final String name;
  final bool archived;

  PaymentMethodModel({
    required this.id,
    required this.name,
    this.archived = false,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      archived: (json['archived'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'archived': archived,
    };
  }
}
