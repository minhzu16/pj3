class CategoryModel {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String? color;
  final String? icon;
  final bool archived;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.color,
    this.icon,
    this.archived = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      archived: (json['archived'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'color': color,
      'icon': icon,
      'archived': archived,
    };
  }
}
