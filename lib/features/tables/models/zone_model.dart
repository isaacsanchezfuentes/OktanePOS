class ZoneModel {
  final String id;
  final String name;
  final int sortOrder;

  const ZoneModel({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sort_order': sortOrder,
    };
  }

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Zona Sin Nombre',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
