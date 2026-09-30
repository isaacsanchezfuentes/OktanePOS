class RestaurantTableModel {
  final String id;
  final String zoneId;
  final int tableNumber;
  final String? label; // Ej. 'B1', 'B2', 'Barra Principal', 'Mesa VIP'
  final int seats;
  final String shape; // 'square', 'round', 'circle', 'stool', 'counter', 'wall', 'bar'
  final double posX; // Coordenada relativa 0.0 - 1.0 en el canvas
  final double posY; // Coordenada relativa 0.0 - 1.0 en el canvas
  final double width; // Ancho relativo o factor de escala (default 0.14)
  final double height; // Alto relativo o factor de escala (default 0.10)
  final String status; // 'free', 'available', 'occupied', 'bill_requested'
  final bool isStructural; // true para barras fijas, muros o pasillos (no reciben comandas)
  final String? assignedWaiter;
  final List<Map<String, dynamic>> activeTickets;

  const RestaurantTableModel({
    required this.id,
    required this.zoneId,
    required this.tableNumber,
    this.label,
    this.seats = 4,
    this.shape = 'square',
    this.posX = 0.5,
    this.posY = 0.5,
    this.width = 0.14,
    this.height = 0.10,
    this.status = 'free',
    this.isStructural = false,
    this.assignedWaiter,
    this.activeTickets = const [],
  });

  static int _parseInt(dynamic val, int defaultValue) {
    if (val == null) return defaultValue;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? defaultValue);
    }
    return defaultValue;
  }

  static double _parseDouble(dynamic val, double defaultValue) {
    if (val == null) return defaultValue;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val) ?? defaultValue;
    }
    return defaultValue;
  }

  static bool _parseBool(dynamic val, bool defaultValue) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is num) return val == 1;
    if (val is String) {
      final s = val.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 't') return true;
      if (s == 'false' || s == '0' || s == 'f') return false;
    }
    return defaultValue;
  }

  RestaurantTableModel copyWith({
    String? id,
    String? zoneId,
    int? tableNumber,
    String? label,
    int? seats,
    String? shape,
    double? posX,
    double? posY,
    double? width,
    double? height,
    String? status,
    bool? isStructural,
    String? assignedWaiter,
    List<Map<String, dynamic>>? activeTickets,
  }) {
    return RestaurantTableModel(
      id: id ?? this.id,
      zoneId: zoneId ?? this.zoneId,
      tableNumber: tableNumber ?? this.tableNumber,
      label: label ?? this.label,
      seats: seats ?? this.seats,
      shape: shape ?? this.shape,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      status: status ?? this.status,
      isStructural: isStructural ?? this.isStructural,
      assignedWaiter: assignedWaiter ?? this.assignedWaiter,
      activeTickets: activeTickets ?? this.activeTickets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zone_id': zoneId,
      'table_number': tableNumber,
      'label': label,
      'seats': seats,
      'shape': shape,
      'pos_x': posX,
      'pos_y': posY,
      'width': width,
      'height': height,
      'status': status,
      'is_structural': isStructural,
      'assigned_waiter': assignedWaiter,
      'active_tickets': activeTickets,
    };
  }

  factory RestaurantTableModel.fromJson(Map<String, dynamic> json) {
    return RestaurantTableModel(
      id: json['id']?.toString() ?? '',
      zoneId: json['zone_id']?.toString() ?? '',
      tableNumber: _parseInt(json['table_number'], 1),
      label: json['label']?.toString(),
      seats: _parseInt(json['seats'], 4),
      shape: json['shape']?.toString() ?? 'square',
      posX: _parseDouble(json['pos_x'], 0.5),
      posY: _parseDouble(json['pos_y'], 0.5),
      width: _parseDouble(json['width'], 0.14),
      height: _parseDouble(json['height'], 0.10),
      status: json['status']?.toString() ?? 'free',
      isStructural: _parseBool(json['is_structural'] ?? json['isStructural'], false),
      assignedWaiter: json['assigned_waiter']?.toString(),
      activeTickets: json['active_tickets'] is List
          ? List<Map<String, dynamic>>.from(json['active_tickets'])
          : [],
    );
  }
}