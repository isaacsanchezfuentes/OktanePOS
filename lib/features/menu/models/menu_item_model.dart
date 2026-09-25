class MenuItemModel {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool isActive;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    this.category = 'Alimentos',
    this.isActive = true,
  });

  MenuItemModel copyWith({
    String? id,
    String? name,
    double? price,
    String? category,
    bool? isActive,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'is_active': isActive,
    };
  }

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? 'Alimentos',
      isActive: json['is_active'] != false,
    );
  }
}
